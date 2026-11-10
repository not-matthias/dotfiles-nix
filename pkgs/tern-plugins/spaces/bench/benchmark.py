"""Benchmark Spaces in real, isolated Tern windows, without changing installed plugins.

From this plugin's directory:
  just bench --baseline-ref HEAD --output /tmp/tern-spaces-benchmark.json

Reports sync() and deferred panel-render time per action, including queued hooks
through the next timer tick (at least 50 ms of Tern's clock). Background polls
also count and are identified separately. Switch samples invoke the registered
workspace command handler; dispatch time covers its synchronous call, not native
input dispatch. Neither metric measures input-to-frame latency, GPU rendering,
asynchronous Git work, or remote network latency. Samples run in separate callbacks
to respect Tern's 50 ms hook budget. Fixtures contain only local terminal workspaces.

The optional baseline is the whole plugin (manifest and Luau modules) at a Git
revision; both sides use the current harness and Tern binary. Only isolated source
copies are instrumented. Rounds alternate variant order and run serially.
JSON retains every sample, source hashes, revision, binary version and run order.
"""

import argparse
import hashlib
import json
import math
import os
import shutil
import statistics
import subprocess
import sys
import time
import tomllib
from pathlib import Path
from tempfile import TemporaryDirectory

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tests"))
from harness import PLUGIN, PLUGIN_ID, Tern  # noqa: E402

SCENARIOS = ("unchanged", "switch", "rename")
SAMPLE_PREFIX = "SPACES_BENCH_SAMPLE "
DONE_MARKER = "SPACES_BENCH_DONE"
MANIFEST = "plugin.toml"
NOT_LOADED = ("bench", "tests")
REPO_ROOT = Path(
    subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], cwd=PLUGIN, text=True
    ).strip()
)


def is_source(path):
    """Whether Tern reads this plugin-relative path when it loads the plugin."""
    if path == MANIFEST:
        return True
    return (
        path.endswith(".luau")
        and path != "tern.d.luau"
        and Path(path).parts[0] not in NOT_LOADED
    )


def positive_int(value):
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return number


def git(*args):
    return subprocess.check_output(["git", *args], cwd=REPO_ROOT, text=True)


def collect_samples(app, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        log = (app.root / "process.log").read_text()
        if app.hook_failures():
            raise RuntimeError(f"Invalid benchmark: Spaces hook failed\n{log}")
        if any(process.poll() is not None for process in app.processes):
            raise RuntimeError(f"Benchmark Tern exited\n{log}")
        if DONE_MARKER in log:
            decoder = json.JSONDecoder()
            return [
                decoder.raw_decode(line.split(SAMPLE_PREFIX, 1)[1])[0]
                for line in log.splitlines()
                if SAMPLE_PREFIX in line
            ]
        # Native control windows do not advance plugin timers while idle.
        app.ctl("wait", "100")
    raise TimeoutError(f"Benchmark did not finish in {timeout}s\n{log}")


def measure(sources, session_count, args):
    with TemporaryDirectory(prefix="tern-bench-", dir="/tmp") as directory:
        app = Tern(Path(directory))
        app.env.update(
            TERN_BENCH_SAMPLES=str(args.samples),
            TERN_BENCH_WARMUP=str(args.warmup),
        )
        try:
            app.start()
            plugin = app.root / "sources" / PLUGIN_ID
            shutil.rmtree(plugin)
            for name, source in sources.items():
                target = plugin / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(source)
            entry = plugin / tomllib.loads(sources[MANIFEST])["window"]
            # Reentrant plugin action dispatch is unavailable inside a plugin hook.
            # Capture the registered handlers instead of duplicating their switch path.
            registration = (
                "local benchmarkCommands = {}\n"
                "local function benchmarkCommand(spec)\n"
                "  benchmarkCommands[spec.id] = spec.run\n"
                "  tern.command(spec)\n"
                "end\n"
            )
            entry.write_text(
                registration
                + entry.read_text().replace("tern.command(", "benchmarkCommand(")
                + "\n"
                + Path(__file__).with_suffix(".luau").read_text()
            )
            reload = subprocess.run(
                [app.binary, "plugin", "reload", PLUGIN_ID, "--json"],
                env=app.env,
                capture_output=True,
                text=True,
                check=True,
                timeout=args.timeout,
            )
            app.ctl("resize", "1000", str(max(720, session_count * 28 + 180)))
            app.lua(
                f"for i = 2, {session_count} do "
                'cx.sessions:create({name=string.format("Workspace %02d", i)}) end'
            )
            app.until(
                lambda: (
                    int(app.lua("return #cx.sessions:list()").split("→ ", 1)[1])
                    == session_count
                )
            )
            app.ctl("ready")
            app.until(app.panel_tree)
            app.ctl("plugins", "run", "plugin.spaces.benchmark")
            samples = collect_samples(app, args.timeout)
            for scenario in SCENARIOS:
                rows = [sample for sample in samples if sample["scenario"] == scenario]
                if len(rows) != args.samples:
                    raise RuntimeError(f"Incomplete {scenario} samples: {len(rows)}")
                if any(not math.isfinite(row["ms"]) or row["ms"] < 0 for row in rows):
                    raise RuntimeError(f"Invalid {scenario} timings: {rows}")
            expected_name = f"Renamed workspace {args.samples + args.warmup:02d}"
            app.until(
                lambda: any(
                    node["text"] == expected_name
                    for node in app.ctl("tree", ".space-name button")["nodes"]
                )
            )
            return {"samples": samples, "jit": json.loads(reload.stdout)["jit"]}
        finally:
            app.close()


def summarize(runs):
    summary = []
    keys = dict.fromkeys((run["sessions"], run["variant"]) for run in runs)
    for session_count, variant in keys:
        matching = [
            run
            for run in runs
            if run["sessions"] == session_count and run["variant"] == variant
        ]
        for scenario in SCENARIOS:
            rounds = [
                [sample for sample in run["samples"] if sample["scenario"] == scenario]
                for run in matching
            ]
            medians = [statistics.median(row["ms"] for row in rows) for rows in rounds]
            samples = [row for rows in rounds for row in rows]
            timings = sorted(row["ms"] for row in samples)
            summary.append(
                {
                    "sessions": session_count,
                    "variant": variant,
                    "scenario": scenario,
                    "median_ms": statistics.median(medians),
                    "p95_ms": timings[math.ceil(len(timings) * 0.95) - 1],
                    "dispatch_median_ms": statistics.median(
                        statistics.median(row["dispatch_ms"] for row in rows)
                        for rows in rounds
                    ),
                    "syncs_per_action": statistics.mean(
                        row["syncs"] for row in samples
                    ),
                    "event_syncs_per_action": statistics.mean(
                        row["syncs"] - row["poll_syncs"] for row in samples
                    ),
                    "flushes_per_action": statistics.mean(
                        row["flushes"] for row in samples
                    ),
                    "views_per_action": statistics.mean(
                        row["views"] for row in samples
                    ),
                    "round_medians_ms": medians,
                }
            )
    return summary


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--baseline-ref", help="Git revision to compare against the working tree"
    )
    parser.add_argument("--sessions", nargs="+", type=positive_int, default=[4, 12, 24])
    parser.add_argument(
        "--samples",
        type=positive_int,
        default=30,
        help="samples per scenario per round",
    )
    parser.add_argument(
        "--warmup", type=positive_int, default=5, help="discarded samples per scenario"
    )
    parser.add_argument("--rounds", type=positive_int, default=3)
    parser.add_argument(
        "--timeout", type=positive_int, default=120, help="seconds per benchmark run"
    )
    parser.add_argument(
        "--output", type=Path, help="write metadata and all raw samples as JSON"
    )
    args = parser.parse_args()
    if not os.environ.get("DISPLAY"):
        parser.error("run inside xvfb-run (see module usage)")
    if min(args.sessions) < 2:
        parser.error("workspace switching requires at least two sessions")

    sources = {
        "current": {
            str(path.relative_to(PLUGIN)): path.read_text()
            for path in sorted(PLUGIN.rglob("*"))
            if path.is_file() and is_source(str(path.relative_to(PLUGIN)))
        }
    }
    baseline = None
    if args.baseline_ref:
        baseline = git(
            "rev-parse", "--verify", f"{args.baseline_ref}^{{commit}}"
        ).strip()
        prefix = str(PLUGIN.relative_to(REPO_ROOT)) + "/"
        files = git("ls-tree", "-r", "--name-only", baseline, "--", prefix).splitlines()
        sources = {
            "baseline": {
                path.removeprefix(prefix): git("show", f"{baseline}:{path}")
                for path in files
                if is_source(path.removeprefix(prefix))
            },
            **sources,
        }
    report = {
        "tern": subprocess.check_output(
            [os.environ.get("TERN_BIN", "tern"), "--version"], text=True
        ).strip(),
        "head": git("rev-parse", "HEAD").strip(),
        "baseline": baseline,
        "source_sha256": {
            name: {
                path: hashlib.sha256(source.encode()).hexdigest()
                for path, source in files.items()
            }
            for name, files in sources.items()
        },
        "samples": args.samples,
        "warmup": args.warmup,
        "rounds": args.rounds,
        "runs": [],
        "complete": False,
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
    for session_count in args.sessions:
        for round_index in range(args.rounds):
            variants = list(sources)
            if round_index % 2:
                variants.reverse()
            for variant in variants:
                print(
                    f"Measuring {variant}: {session_count} sessions, round {round_index + 1}/{args.rounds}",
                    flush=True,
                )
                report["runs"].append(
                    {
                        "variant": variant,
                        "sessions": session_count,
                        "round": round_index + 1,
                        **measure(sources[variant], session_count, args),
                    }
                )
                if args.output:
                    args.output.write_text(json.dumps(report, indent=2) + "\n")
    report["summary"] = summarize(report["runs"])
    report["complete"] = True
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n")
        print(f"Raw results: {args.output}")
    print(
        "\nMedian = median of round medians; p95 = pooled samples. Plugin time includes sync and deferred rendering."
    )
    print(
        "| Sessions | Variant | Scenario | Plugin median ms | Plugin p95 ms | Dispatch ms | Event syncs/action | Views/action |"
    )
    print("|---:|---|---|---:|---:|---:|---:|---:|")
    for row in report["summary"]:
        print(
            f"| {row['sessions']} | {row['variant']} | {row['scenario']} | "
            f"{row['median_ms']:.3f} | {row['p95_ms']:.3f} | "
            f"{row['dispatch_median_ms']:.3f} | {row['event_syncs_per_action']:.2f} | {row['views_per_action']:.2f} |"
        )


if __name__ == "__main__":
    main()
