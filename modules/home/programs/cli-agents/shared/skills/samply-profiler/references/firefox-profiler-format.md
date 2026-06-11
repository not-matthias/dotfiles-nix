# Firefox Profiler JSON Format for Samply

`samply` writes gzip-compressed Firefox Profiler JSON, usually as `profile.json.gz`. Firefox Profiler can also load the same JSON from a `from-url` link.

Sources:
- <https://github.com/firefox-devtools/profiler>
- <https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/gecko-profile-format.md>
- <https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/processed-profile-format.md>
- <https://raw.githubusercontent.com/firefox-devtools/profiler/main/docs-developer/CHANGELOG-formats.md>

## Top-Level Shape

```json
{
  "meta": { "product": "...", "interval": 1.0, "version": 24 },
  "libs": [ { "name": "...", "path": "...", "breakpadId": "..." } ],
  "threads": [ ... ],
  "pages": [],
  "counters": []
}
```

Processed profiles may also contain top-level `shared` tables:

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

Older samply captures commonly store those tables directly on each thread.

## Stack Walking

Samples reference stacks through `threads[].samples.stack[i]`.

Follow this chain for each non-null sample stack:

```text
samples.stack[i]
  -> stackTable.frame[stack_index]
  -> frameTable.func[frame_index]
  -> funcTable.name[func_index]
  -> stringArray[name_index]
```

`stackTable.prefix[stack_index]` points to the caller frame. Follow `prefix` until `null` to walk from leaf to root. Reverse the resulting frame list to print a top-down call tree.

## Resource and Library Lookup

Function resources map frames to libraries:

```text
funcTable.resource[func_index]
  -> resourceTable.name[resource_index]
  -> resourceTable.lib[resource_index]
  -> libs[lib_index]
```

`libs[].path` is the best first guess for the binary to pass to `addr2line`.

## Symbolication

Raw captures may contain frame names like `0x9b50bd4`. Resolve them offline with:

```bash
addr2line -f -C -e /path/to/binary 0xADDR1 0xADDR2
```

Firefox Profiler can use a symbol server while viewing the profile. Offline CLI analysis must either use the exact binary from `libs[].path` or a manually supplied replacement path.

## Analysis Metrics

- **Self time**: Counts samples where a frame is the leaf frame.
- **Total time**: Counts samples where a frame appears anywhere in the stack.
- **Call tree percentage**: Inclusive sample percentage for a top-down frame path.

These are sample counts, not exact CPU cycles. Treat very small differences as noise unless repeated captures confirm them.
