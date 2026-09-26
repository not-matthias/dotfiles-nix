import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT_PATH = Path(__file__).parents[1] / "check-package-updates.py"
SPEC = importlib.util.spec_from_file_location("package_updates", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
package_updates = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = package_updates
SPEC.loader.exec_module(package_updates)


class PackageDiscoveryTests(unittest.TestCase):
    def test_fetch_pypi_source_name_is_not_reported_as_a_package(self) -> None:
        contents = """
        pname = "client";
        version = "1.0.0";
        src = fetchPypi {
          pname = "client_source";
          inherit version;
        };
        pname = "other";
        version = "2.0.0";
        """

        sections = package_updates.package_sections(contents)

        self.assertEqual([name for name, _, _ in sections], ["client", "other"])

    def test_first_source_expression_selects_the_package_upstream(self) -> None:
        section = """
        src = fetchPypi {
          pname = "client-source";
        };
        source = fetchFromGitHub {
          owner = "example";
          repo = "later-source";
        };
        """

        provider, upstream, reason = package_updates.detect_source(section, "client")

        self.assertEqual((provider, upstream, reason), ("pypi", "client-source", None))

    def test_override_can_register_a_package_without_literal_pname(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            package_file = root / "pkgs" / "extension.nix"
            package_file.parent.mkdir()
            package_file.write_text('version = "1.2.3";\n')
            override = package_updates.Override(
                path="pkgs/extension.nix",
                name="extension",
                provider="github-release",
                upstream="example/extension",
                version_pattern=r'version = "([^"]+)";',
            )

            packages = package_updates.discover_packages(root, {override.key: override})

        self.assertEqual(
            packages,
            [
                package_updates.Package(
                    path="pkgs/extension.nix",
                    name="extension",
                    version="1.2.3",
                    provider="github-release",
                    upstream="example/extension",
                )
            ],
        )

    def test_flake_comparison_uses_the_candidate_root_mapping(self) -> None:
        current = {
            "nodes": {
                "root": {"inputs": {"nixpkgs": "nixpkgs"}},
                "nixpkgs": {
                    "locked": {
                        "type": "github",
                        "owner": "NixOS",
                        "repo": "nixpkgs",
                        "rev": "old",
                    }
                },
            }
        }
        candidate = {
            "nodes": {
                "root": {"inputs": {"nixpkgs": "nixpkgs-updated"}},
                "nixpkgs-updated": {
                    "locked": {
                        "type": "github",
                        "owner": "NixOS",
                        "repo": "nixpkgs",
                        "rev": "new",
                    }
                },
            }
        }

        results = package_updates.compare_flake_locks(current, candidate)

        self.assertEqual(
            results,
            [
                package_updates.Result(
                    scope="flake",
                    name="nixpkgs",
                    current="NixOS/nixpkgs@old",
                    latest="NixOS/nixpkgs@new",
                    status="UPDATE",
                    detail="",
                )
            ],
        )


if __name__ == "__main__":
    unittest.main()
