#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# ///
"""Analyze Firefox Profiler JSON files emitted by samply."""

from __future__ import annotations

import argparse
import gzip
import json
import re
import subprocess
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

HEX_ADDRESS = re.compile(r"^0x[0-9a-fA-F]+$")


def load_profile(path: str) -> dict[str, Any]:
    if path == "-":
        return json.load(sys.stdin)

    raw = Path(path).read_bytes()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)

    return json.loads(raw)


def get_table(profile: dict[str, Any], thread: dict[str, Any], name: str) -> dict[str, Any]:
    if name in thread:
        return thread[name]

    shared = profile.get("shared", {})
    if name in shared:
        return shared[name]

    raise KeyError(f"missing {name}")


def get_strings(profile: dict[str, Any], thread: dict[str, Any]) -> list[str]:
    shared = profile.get("shared", {})
    strings = thread.get("stringArray") or thread.get("stringTable")
    strings = strings or shared.get("stringArray") or shared.get("stringTable")
    if strings is None:
        raise KeyError("missing stringArray/stringTable")
    return strings


def sample_count(thread: dict[str, Any]) -> int:
    samples = thread.get("samples", {})
    return len(samples.get("stack") or samples.get("time") or [])


def select_thread(profile: dict[str, Any], thread_index: int | None, auto: bool) -> int:
    threads = profile.get("threads", [])
    if not threads:
        raise SystemExit("profile contains no threads")

    if auto:
        return max(range(len(threads)), key=lambda index: sample_count(threads[index]))

    if thread_index is None:
        raise SystemExit("specify --thread N or --auto")

    if thread_index < 0 or thread_index >= len(threads):
        raise SystemExit(f"thread index {thread_index} out of range 0..{len(threads) - 1}")

    return thread_index


def func_name(profile: dict[str, Any], thread: dict[str, Any], frame_index: int) -> str:
    frame_table = get_table(profile, thread, "frameTable")
    func_table = get_table(profile, thread, "funcTable")
    strings = get_strings(profile, thread)

    func_index = frame_table["func"][frame_index]
    name_index = func_table["name"][func_index]
    return strings[name_index]


def walk_stack(profile: dict[str, Any], thread: dict[str, Any], stack_index: int | None) -> list[str]:
    if stack_index is None or stack_index < 0:
        return []

    stack_table = get_table(profile, thread, "stackTable")
    frames = []

    while stack_index is not None and stack_index >= 0:
        frame_index = stack_table["frame"][stack_index]
        frames.append(func_name(profile, thread, frame_index))
        stack_index = stack_table["prefix"][stack_index]

    return frames


def thread_samples(profile: dict[str, Any], thread: dict[str, Any]) -> list[list[str]]:
    samples = thread.get("samples", {})
    stacks = samples.get("stack", [])
    return [walk_stack(profile, thread, stack_index) for stack_index in stacks]


def collect_addresses(profile: dict[str, Any], thread: dict[str, Any]) -> set[str]:
    func_table = get_table(profile, thread, "funcTable")
    strings = get_strings(profile, thread)
    addresses = set()

    for name_index in func_table.get("name", []):
        name = strings[name_index]
        if HEX_ADDRESS.match(name):
            addresses.add(name)

    return addresses


def find_binary(profile: dict[str, Any], thread: dict[str, Any]) -> str | None:
    libs = profile.get("libs", [])
    if not libs:
        return None

    func_table = get_table(profile, thread, "funcTable")
    resource_table = get_table(profile, thread, "resourceTable")
    resource_counts = Counter(resource for resource in func_table.get("resource", []) if resource is not None and resource >= 0)
    resource_libs = resource_table.get("lib", [])

    for resource_index, _ in resource_counts.most_common():
        if resource_index >= len(resource_libs):
            continue

        lib_index = resource_libs[resource_index]
        if lib_index is None or lib_index >= len(libs):
            continue

        path = libs[lib_index].get("path", "")
        if Path(path).exists():
            return path

    return None


def resolve_symbols(addresses: set[str], binary: str | None) -> dict[str, str]:
    if not addresses or not binary:
        return {}

    ordered = sorted(addresses)
    result = subprocess.run(
        ["addr2line", "-f", "-C", "-e", binary, *ordered],
        check=False,
        capture_output=True,
        text=True,
        timeout=60,
    )

    resolved = {}
    lines = result.stdout.splitlines()
    for line_index in range(0, len(lines) - 1, 2):
        address_index = line_index // 2
        if address_index >= len(ordered):
            break

        name = lines[line_index].strip()
        if name and name not in {"??", "???"}:
            resolved[ordered[address_index]] = name

    return resolved


def resolve_frame(name: str, resolved: dict[str, str]) -> str:
    return resolved.get(name, name)


def print_threads(profile: dict[str, Any]) -> None:
    threads = profile.get("threads", [])
    print(f"threads: {len(threads)}")
    for index, thread in enumerate(threads):
        count = sample_count(thread)
        hot = "  <-- hottest" if count == max(sample_count(t) for t in threads) and count else ""
        name = thread.get("name") or thread.get("processName") or "unnamed"
        print(f"[{index:3d}] {count:8d} samples  {name}{hot}")


def print_libs(profile: dict[str, Any]) -> None:
    for index, lib in enumerate(profile.get("libs", [])):
        name = lib.get("name", "?")
        path = lib.get("path", "?")
        debug_name = lib.get("debugName") or ""
        print(f"[{index:3d}] {name}  {path}  {debug_name}")


def prepare_symbols(args: argparse.Namespace, profile: dict[str, Any], thread: dict[str, Any]) -> dict[str, str]:
    binary = args.binary
    if args.resolve and not binary:
        binary = find_binary(profile, thread)

    if not args.resolve and not binary:
        return {}

    if not binary:
        print("warning: could not find binary; use --binary /path/to/bin", file=sys.stderr)
        return {}

    addresses = collect_addresses(profile, thread)
    resolved = resolve_symbols(addresses, binary)
    print(f"resolved {len(resolved)}/{len(addresses)} addresses using {binary}")
    return resolved


def print_flat(args: argparse.Namespace, profile: dict[str, Any]) -> None:
    thread_index = select_thread(profile, args.thread, args.auto)
    thread = profile["threads"][thread_index]
    resolved = prepare_symbols(args, profile, thread)
    samples = thread_samples(profile, thread)
    total = len(samples)
    self_counts: Counter[str] = Counter()
    total_counts: Counter[str] = Counter()

    for frames in samples:
        frames = [resolve_frame(frame, resolved) for frame in frames]
        if not frames:
            continue

        self_counts[frames[0]] += 1
        total_counts.update(set(frames))

    name = thread.get("name", "unnamed")
    print(f"thread [{thread_index}] {name}: {total} samples")
    print("\nself time")
    print_counts(self_counts, total, args.top)
    print("\ntotal time")
    print_counts(total_counts, total, args.top)


def print_counts(counts: Counter[str], total: int, top: int) -> None:
    for name, count in counts.most_common(top):
        percent = count / total * 100 if total else 0.0
        print(f"{percent:6.2f}%  {count:8d}  {name}")


@dataclass
class Node:
    name: str
    self_count: int = 0
    total_count: int = 0
    children: dict[str, "Node"] = field(default_factory=dict)


def print_tree(args: argparse.Namespace, profile: dict[str, Any]) -> None:
    thread_index = select_thread(profile, args.thread, args.auto)
    thread = profile["threads"][thread_index]
    resolved = prepare_symbols(args, profile, thread)
    root = Node("(root)")
    samples = thread_samples(profile, thread)
    total = len(samples)

    for frames in samples:
        frames = [resolve_frame(frame, resolved) for frame in reversed(frames)]
        if not frames:
            continue

        node = root
        node.total_count += 1
        for frame in frames:
            child = node.children.setdefault(frame, Node(frame))
            child.total_count += 1
            node = child
        node.self_count += 1

    name = thread.get("name", "unnamed")
    print(f"thread [{thread_index}] {name}: {total} samples")
    for child in sorted(root.children.values(), key=lambda item: item.total_count, reverse=True):
        emit_node(child, total, args.depth, args.min_pct, 1)


def emit_node(node: Node, total: int, max_depth: int, min_pct: float, depth: int) -> None:
    if depth > max_depth:
        return

    percent = node.total_count / total * 100 if total else 0.0
    if percent < min_pct:
        return

    self_percent = node.self_count / total * 100 if total else 0.0
    self_suffix = f" self={self_percent:.1f}%" if self_percent >= 0.5 else ""
    print(f"{'  ' * (depth - 1)}{percent:6.2f}%  {node.name}{self_suffix}")

    children = sorted(node.children.values(), key=lambda item: item.total_count, reverse=True)
    for child in children:
        emit_node(child, total, max_depth, min_pct, depth + 1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze samply profile.json.gz files")
    parser.add_argument("profile", help="profile.json, profile.json.gz, or '-' for stdin")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("threads", help="list threads by sample count")
    subparsers.add_parser("libs", help="list libraries recorded in the profile")

    flat = subparsers.add_parser("flat", help="show self-time and total-time hot functions")
    add_thread_args(flat)
    flat.add_argument("--top", type=int, default=30)
    flat.set_defaults(func=print_flat)

    tree = subparsers.add_parser("tree", help="show a top-down call tree")
    add_thread_args(tree)
    tree.add_argument("--depth", type=int, default=12)
    tree.add_argument("--min-pct", type=float, default=1.0)
    tree.set_defaults(func=print_tree)

    args = parser.parse_args()
    profile = load_profile(args.profile)

    if args.command == "threads":
        print_threads(profile)
        return

    if args.command == "libs":
        print_libs(profile)
        return

    args.func(args, profile)


def add_thread_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--thread", type=int, default=None, help="thread index")
    parser.add_argument("--auto", action="store_true", help="select thread with most samples")
    parser.add_argument("--resolve", action="store_true", help="resolve raw hex addresses with addr2line")
    parser.add_argument("--binary", default=None, help="binary path for addr2line")


if __name__ == "__main__":
    main()
