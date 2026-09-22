# Firefox Profiler JSON Format for Samply

`samply` commonly writes gzip-compressed Firefox Profiler JSON as `profile.json.gz`. Firefox Profiler can also load the same JSON from a `from-url` link. This reference covers the JSON table relationships and offline symbolication; it does not describe binary JSLB input.

Sources:

- <https://github.com/firefox-devtools/profiler>
- <https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/gecko-profile-format.md>
- <https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/processed-profile-format.md>
- <https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/CHANGELOG-formats.md>

## Top-level shape

```json
{
  "meta": { "product": "...", "interval": 1.0, "version": 24 },
  "libs": [ { "name": "...", "path": "...", "breakpadId": "..." } ],
  "threads": [ ... ],
  "pages": [],
  "counters": []
}
```

Processed profiles may store shared tables at the top level:

```json
{
  "shared": {
    "stringArray": [],
    "stackTable": {},
    "frameTable": {},
    "funcTable": {},
    "resourceTable": {},
    "nativeSymbols": {}
  },
  "threads": [ { "samples": {} } ]
}
```

Older Samply captures commonly keep those tables on each thread. The bundled analyzer supports both placements, but only for JSON input.

## Stack walking

Samples reference stacks through `threads[].samples.stack[i]`:

```text
samples.stack[i]
  -> stackTable.frame[stack_index]
  -> frameTable.func[frame_index]
  -> funcTable.name[func_index]
  -> stringArray[name_index]
```

`stackTable.prefix[stack_index]` points to the caller frame. Follow `prefix` until `null` to walk leaf-to-root, then reverse the list for a top-down call tree. Guard indices and cycles when writing an independent parser.

## Resource and library lookup

Function resources map frames to libraries:

```text
funcTable.resource[func_index]
  -> resourceTable.name[resource_index]
  -> resourceTable.lib[resource_index]
  -> libs[lib_index]
```

`libs[].path` is the first candidate for `addr2line`, but it may be a path from the machine that captured the profile. Treat it as a hint until the file, build, and symbol data are confirmed to match.

## Exact offline symbolication

Raw captures may contain names such as `0x9b50bd4`. Resolve several addresses in one invocation:

```bash
addr2line -f -C -e /path/to/exact/binary 0xADDR1 0xADDR2
```

Use the exact executable or library used for the capture whenever possible. A replacement with a different build can map an address to the wrong function or line even when its filename and version look similar. If the profile's `libs[].path` is unavailable, pass the verified replacement through the analyzer:

```bash
SKILL_DIR=/path/to/samply-profiler
uv run python "$SKILL_DIR/scripts/analyze_profile.py" profile.json.gz \
  flat --auto --resolve --binary /path/to/exact/binary --top 40
```

On NixOS, match each library name from `libs[]` to the exact `/nix/store` dependency used by the captured executable. Use `ldd /path/to/main-binary` to identify the loaded store paths, and prefer matching debug outputs when line numbers are needed:

```bash
find /nix/store -name 'libc.so.6' 2>/dev/null
ldd /path/to/main-binary
find /nix/store -path '*debug*' -name 'libnixexpr.so.2.34.7' 2>/dev/null
```

Stripped binaries can still provide dynamic-symbol function names; matching debug data adds file and line information. Batch addresses rather than starting one `addr2line` process per frame.

## Samples and CPU interpretation

- `samples.stack[]` identifies the call stack for each sample.
- `samples.threadCPUDelta[]` is a per-sample CPU-time delta in microseconds: values greater than zero indicate on-CPU work, while zero can indicate idle or blocked time.
- `samples.weight[]` is commonly one per sample and should be respected by a parser that supports weighted samples.
- `meta.interval` records the sampling interval, commonly in milliseconds.
- **Self time** counts samples where a frame is the leaf; **total time** counts samples where it appears anywhere in the stack. These are sample-derived estimates, not exact CPU-cycle counts.

For broader profiles, aggregate by `processName`, filter on positive `threadCPUDelta` when looking for CPU hotspots, symbolicate the top-N self-time addresses per process, build inclusive chains for the hottest leaves, and check thread counts for oversubscription. For a single command, first verify that the highest-sample thread is the workload thread rather than a runtime helper, idle thread, GC thread, or background service.

Treat very small percentage differences as noise until repeated, like-for-like captures confirm them.
