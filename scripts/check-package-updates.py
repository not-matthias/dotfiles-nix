#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Report available updates for flake inputs and custom package sources.

Nixpkgs package sets are covered by their pinned flake input revisions. Custom
derivations with literal ``pname`` and ``version`` fields are discovered from
``pkgs/**/*.nix``. GitHub releases/tags, PyPI, and npm sources are checked;
other sources are reported for manual review. Add an entry to
``scripts/package-update-overrides.toml`` for a non-standard source.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import os
import re
import ssl
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass, replace
from pathlib import Path
from typing import Any, Literal

import tomllib

DEFAULT_TIMEOUT_SECONDS = 20
MAX_REQUEST_WORKERS = 8
PACKAGE_NAME_RE = re.compile(r'\bpname\s*=\s*"(?P<name>[^"]+)"\s*;')
VERSION_RE = re.compile(r'\bversion\s*=\s*"(?P<version>[^"]+)"\s*;')
GITHUB_SOURCE_RE = re.compile(
    r"fetchFromGitHub\s*\{(?:(?!\}).)*?"
    r'\bowner\s*=\s*"(?P<owner>[^"]+)"\s*;(?:(?!\}).)*?'
    r'\brepo\s*=\s*"(?P<repo>[^"]+)"\s*;',
    re.DOTALL,
)
GITHUB_URL_RE = re.compile(r"github\.com/(?P<owner>[^/\"?#]+)/(?P<repo>[^/\"?#]+)")
PYPI_SOURCE_RE = re.compile(
    r"fetchPypi\s*\{(?:(?!\}).)*?\bpname\s*=\s*\"(?P<name>[^\"]+)\"\s*;",
    re.DOTALL,
)
NPM_URL_RE = re.compile(r"registry\.npmjs\.org/(?P<name>@?[^/\"?#]+(?:/[^/\"?#]+)?)/-")

Provider = Literal["github-release", "github-tag", "npm", "pypi", "manual"]
Status = Literal["CURRENT", "UPDATE", "MANUAL", "ERROR"]


@dataclass(frozen=True)
class Package:
    path: str
    name: str
    version: str
    provider: Provider | None
    upstream: str | None
    reason: str | None = None

    @property
    def key(self) -> tuple[str, str]:
        return (self.path, self.name)


@dataclass(frozen=True)
class Result:
    scope: Literal["flake", "package"]
    name: str
    current: str | None
    latest: str | None
    status: Status
    detail: str


@dataclass(frozen=True)
class Override:
    path: str
    name: str
    provider: Provider
    upstream: str | None = None
    reason: str | None = None
    version_pattern: str | None = None

    @property
    def key(self) -> tuple[str, str]:
        return (self.path, self.name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check flake inputs and versioned custom pkgs/ derivations."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="repository root (default: script parent)",
    )
    parser.add_argument(
        "--config",
        type=Path,
        help="TOML overrides file (default: scripts/package-update-overrides.toml)",
    )
    parser.add_argument(
        "--no-flake",
        action="store_true",
        help="skip the temporary flake-lock update check",
    )
    parser.add_argument(
        "--no-custom",
        action="store_true",
        help="skip custom package source checks",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="emit machine-readable JSON",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero when updates, errors, or manual checks remain",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_TIMEOUT_SECONDS,
        help=f"HTTP timeout in seconds (default: {DEFAULT_TIMEOUT_SECONDS})",
    )
    return parser.parse_args()


def load_overrides(path: Path) -> dict[tuple[str, str], Override]:
    if not path.exists():
        return {}

    with path.open("rb") as file:
        data = tomllib.load(file)

    overrides: dict[tuple[str, str], Override] = {}
    for entry in data.get("package", []):
        provider = entry.get("provider")
        if provider not in {"github-release", "github-tag", "npm", "pypi", "manual"}:
            raise ValueError(f"{path}: unsupported provider {provider!r}")

        override = Override(
            path=entry["path"],
            name=entry["name"],
            provider=provider,
            upstream=entry.get("upstream"),
            reason=entry.get("reason"),
            version_pattern=entry.get("version_pattern"),
        )
        if override.key in overrides:
            raise ValueError(
                f"{path}: duplicate override for {override.path}:{override.name}"
            )
        overrides[override.key] = override

    return overrides


def is_fetch_pypi_argument(contents: str, position: int) -> bool:
    return contents.rfind("fetchPypi", 0, position) > contents.rfind("}", 0, position)


def package_sections(contents: str) -> list[tuple[str, str, str]]:
    """Return derivation sections that have literal pname and version fields."""
    pname_matches = [
        match
        for match in PACKAGE_NAME_RE.finditer(contents)
        if not is_fetch_pypi_argument(contents, match.start())
    ]
    starts: list[tuple[int, str, str]] = []
    for index, match in enumerate(pname_matches):
        next_pname = (
            pname_matches[index + 1].start()
            if index + 1 < len(pname_matches)
            else len(contents)
        )
        version_match = VERSION_RE.search(contents, match.end(), next_pname)
        if version_match is None:
            continue
        starts.append(
            (match.start(), match.group("name"), version_match.group("version"))
        )

    sections: list[tuple[str, str, str]] = []
    for index, (start, name, version) in enumerate(starts):
        end = starts[index + 1][0] if index + 1 < len(starts) else len(contents)
        sections.append((name, version, contents[start:end]))
    return sections


def detect_source(
    section: str, package_name: str
) -> tuple[Provider | None, str | None, str | None]:
    sources: list[tuple[int, Provider, str]] = []

    github_source = GITHUB_SOURCE_RE.search(section)
    if github_source:
        repository = f"{github_source.group('owner')}/{github_source.group('repo')}"
        sources.append((github_source.start(), "github-release", repository))

    github_url = GITHUB_URL_RE.search(section)
    if github_url:
        repository = f"{github_url.group('owner')}/{github_url.group('repo')}"
        sources.append((github_url.start(), "github-release", repository))

    pypi_source = PYPI_SOURCE_RE.search(section)
    if pypi_source:
        upstream = pypi_source.group("name")
        resolved_name = package_name if upstream.startswith("${") else upstream
        sources.append((pypi_source.start(), "pypi", resolved_name))
    elif "fetchPypi" in section:
        sources.append((section.index("fetchPypi"), "pypi", package_name))

    npm_url = NPM_URL_RE.search(section)
    if npm_url:
        upstream = npm_url.group("name")
        resolved_name = package_name if upstream.startswith("${") else upstream
        sources.append((npm_url.start(), "npm", resolved_name))

    if not sources:
        return None, None, "no supported upstream source was detected"

    _, provider, upstream = min(sources)
    return provider, upstream, None


def discover_packages(
    root: Path, overrides: dict[tuple[str, str], Override]
) -> list[Package]:
    packages: list[Package] = []
    contents_by_path: dict[str, str] = {}
    for path in sorted((root / "pkgs").rglob("*.nix")):
        relative_path = path.relative_to(root).as_posix()
        contents = path.read_text()
        contents_by_path[relative_path] = contents
        for name, version, section in package_sections(contents):
            provider, upstream, reason = detect_source(section, name)
            package = Package(relative_path, name, version, provider, upstream, reason)
            override = overrides.get(package.key)
            if override is not None:
                package = replace(
                    package,
                    provider=override.provider,
                    upstream=override.upstream or package.upstream,
                    reason=override.reason,
                )
            packages.append(package)

    unique_packages: dict[tuple[str, str], Package] = {}
    for package in packages:
        existing = unique_packages.get(package.key)
        if existing is not None and existing != package:
            raise ValueError(
                f"duplicate package definition for {package.path}:{package.name}"
            )
        unique_packages[package.key] = package
    packages = list(unique_packages.values())

    discovered_keys = {package.key for package in packages}
    for override in overrides.values():
        if override.key in discovered_keys:
            continue
        if override.version_pattern is None:
            raise ValueError(
                f"override for {override.path}:{override.name} did not match a discovered package"
            )
        contents = contents_by_path.get(override.path)
        if contents is None:
            raise ValueError(
                f"override references missing package file {override.path}"
            )

        version_match = re.search(override.version_pattern, contents)
        if version_match is None or version_match.lastindex is None:
            raise ValueError(
                f"override for {override.path}:{override.name} must capture the version"
            )
        packages.append(
            Package(
                override.path,
                override.name,
                version_match.group(1),
                override.provider,
                override.upstream,
                override.reason,
            )
        )
    return packages


def github_api(path: str, timeout: int) -> Any:
    completed = subprocess.run(
        ["gh", "api", path],
        capture_output=True,
        text=True,
        check=False,
        env={**os.environ, "GH_PROMPT_DISABLED": "1"},
        timeout=timeout,
    )
    if completed.returncode == 0:
        return json.loads(completed.stdout)
    if "HTTP 404" in completed.stderr:
        raise FileNotFoundError(path)
    raise RuntimeError(completed.stderr.strip() or f"gh api {path} failed")


def certificate_context() -> ssl.SSLContext:
    configured_bundle = os.environ.get("SSL_CERT_FILE") or os.environ.get(
        "NIX_SSL_CERT_FILE"
    )
    if configured_bundle:
        return ssl.create_default_context(cafile=configured_bundle)

    for bundle in (
        Path("/etc/ssl/certs/ca-bundle.crt"),
        Path("/etc/ssl/certs/ca-certificates.crt"),
    ):
        if bundle.exists():
            return ssl.create_default_context(cafile=bundle)
    return ssl.create_default_context()


def request_json(url: str, timeout: int) -> Any:
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "dotfiles-package-check",
        },
    )
    with urllib.request.urlopen(
        request, timeout=timeout, context=certificate_context()
    ) as response:
        return json.load(response)


def github_latest(repository: str, timeout: int, tags_only: bool) -> str:
    if not tags_only:
        try:
            release = github_api(f"repos/{repository}/releases/latest", timeout)
            return release["tag_name"]
        except FileNotFoundError:
            pass

    tags = github_api(f"repos/{repository}/tags?per_page=1", timeout)
    if not tags:
        raise ValueError("upstream has no releases or tags")
    return tags[0]["name"]


def pypi_latest(package: str, timeout: int) -> str:
    encoded_package = urllib.parse.quote(package)
    data = request_json(f"https://pypi.org/pypi/{encoded_package}/json", timeout)
    return data["info"]["version"]


def npm_latest(package: str, timeout: int) -> str:
    encoded_package = urllib.parse.quote(package, safe="@")
    data = request_json(f"https://registry.npmjs.org/{encoded_package}/latest", timeout)
    return data["version"]


def normalize_version(version: str) -> str:
    return version.removeprefix("v").lower()


def query_upstream(package: Package, timeout: int) -> str:
    if package.provider == "github-release":
        assert package.upstream is not None
        return github_latest(package.upstream, timeout, tags_only=False)
    if package.provider == "github-tag":
        assert package.upstream is not None
        return github_latest(package.upstream, timeout, tags_only=True)
    if package.provider == "pypi":
        assert package.upstream is not None
        return pypi_latest(package.upstream, timeout)
    if package.provider == "npm":
        assert package.upstream is not None
        return npm_latest(package.upstream, timeout)
    raise ValueError(package.reason or "no supported upstream source was detected")


def package_results(packages: list[Package], timeout: int) -> list[Result]:
    results: list[Result] = []
    requests: dict[tuple[str, str], concurrent.futures.Future[str]] = {}

    with concurrent.futures.ThreadPoolExecutor(
        max_workers=MAX_REQUEST_WORKERS
    ) as executor:
        for package in packages:
            if package.provider in {None, "manual"} or package.upstream is None:
                continue
            key = (package.provider, package.upstream)
            requests.setdefault(key, executor.submit(query_upstream, package, timeout))

        for package in packages:
            display_name = f"{package.path}:{package.name}"
            if package.provider in {None, "manual"} or package.upstream is None:
                results.append(
                    Result(
                        "package",
                        display_name,
                        package.version,
                        None,
                        "MANUAL",
                        package.reason or "no supported upstream source was detected",
                    )
                )
                continue

            future = requests[(package.provider, package.upstream)]
            try:
                latest = future.result()
            except (
                KeyError,
                OSError,
                RuntimeError,
                ValueError,
                subprocess.TimeoutExpired,
                urllib.error.HTTPError,
            ) as error:
                results.append(
                    Result(
                        "package",
                        display_name,
                        package.version,
                        None,
                        "ERROR",
                        str(error),
                    )
                )
                continue

            status: Status = (
                "CURRENT"
                if normalize_version(package.version) == normalize_version(latest)
                else "UPDATE"
            )
            results.append(
                Result(
                    "package",
                    display_name,
                    package.version,
                    latest,
                    status,
                    f"{package.provider}: {package.upstream}",
                )
            )

    return results


def node_identity(node: dict[str, Any]) -> str:
    locked = node.get("locked", {})
    source_type = locked.get("type", "unknown")
    if source_type == "github":
        return f"{locked['owner']}/{locked['repo']}@{locked.get('rev', locked.get('narHash', '?'))}"
    if source_type == "git":
        return (
            f"{locked.get('url', '?')}@{locked.get('rev', locked.get('narHash', '?'))}"
        )
    return locked.get("rev", locked.get("narHash", source_type))


def compare_flake_locks(
    current: dict[str, Any], candidate: dict[str, Any]
) -> list[Result]:
    current_root = current["nodes"]["root"]
    candidate_root = candidate["nodes"]["root"]
    candidate_nodes = candidate["nodes"]
    results: list[Result] = []
    for name, current_node_name in sorted(current_root.get("inputs", {}).items()):
        candidate_node_name = candidate_root.get("inputs", {}).get(name)
        if not isinstance(current_node_name, str) or not isinstance(
            candidate_node_name, str
        ):
            results.append(
                Result(
                    "flake",
                    name,
                    None,
                    None,
                    "MANUAL",
                    "input follows another lock node",
                )
            )
            continue
        current_node = current["nodes"][current_node_name]
        candidate_node = candidate_nodes.get(candidate_node_name)
        if candidate_node is None:
            results.append(
                Result(
                    "flake",
                    name,
                    node_identity(current_node),
                    None,
                    "ERROR",
                    "input disappeared from candidate lock",
                )
            )
            continue

        current_identity = node_identity(current_node)
        candidate_identity = node_identity(candidate_node)
        status: Status = (
            "CURRENT" if current_identity == candidate_identity else "UPDATE"
        )
        results.append(
            Result("flake", name, current_identity, candidate_identity, status, "")
        )
    return results


def flake_results(root: Path) -> list[Result]:
    current_lock_path = root / "flake.lock"
    if not current_lock_path.exists():
        return [
            Result(
                "flake", "flake.lock", None, None, "ERROR", "flake.lock does not exist"
            )
        ]

    cache_root = root / ".agents" / "tmp"
    cache_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix="package-update-", dir=cache_root
    ) as temporary_directory:
        candidate_lock_path = Path(temporary_directory) / "flake.lock"
        completed = subprocess.run(
            [
                "nix",
                "flake",
                "update",
                "--flake",
                str(root),
                "--output-lock-file",
                str(candidate_lock_path),
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode != 0:
            detail = (
                completed.stderr.strip().splitlines()[-1]
                if completed.stderr.strip()
                else "nix flake update failed"
            )
            return [Result("flake", "flake inputs", None, None, "ERROR", detail)]

        current = json.loads(current_lock_path.read_text())
        candidate = json.loads(candidate_lock_path.read_text())
    return compare_flake_locks(current, candidate)


def render_text(results: list[Result]) -> None:
    for scope in ("flake", "package"):
        scope_results = [result for result in results if result.scope == scope]
        if not scope_results:
            continue
        print(f"{scope.title()} checks")
        for result in scope_results:
            latest = result.latest or "-"
            detail = f" ({result.detail})" if result.detail else ""
            print(
                f"{result.status:7} {result.name}: {result.current or '-'} -> {latest}{detail}"
            )

    counts = {
        status: sum(result.status == status for result in results)
        for status in ("UPDATE", "CURRENT", "MANUAL", "ERROR")
    }
    print(
        "\nSummary: "
        + ", ".join(f"{count} {status.lower()}" for status, count in counts.items())
    )


def check_exit_code(results: list[Result]) -> int:
    if any(result.status in {"ERROR", "MANUAL"} for result in results):
        return 2
    return 1 if any(result.status == "UPDATE" for result in results) else 0


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    config_path = args.config or root / "scripts" / "package-update-overrides.toml"

    try:
        overrides = load_overrides(config_path)
    except (OSError, KeyError, ValueError, tomllib.TOMLDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    results: list[Result] = []
    if not args.no_flake:
        results.extend(flake_results(root))
    if not args.no_custom:
        results.extend(
            package_results(discover_packages(root, overrides), args.timeout)
        )

    if args.json:
        print(json.dumps([asdict(result) for result in results], indent=2))
    else:
        render_text(results)

    return check_exit_code(results) if args.check else 0


if __name__ == "__main__":
    raise SystemExit(main())
