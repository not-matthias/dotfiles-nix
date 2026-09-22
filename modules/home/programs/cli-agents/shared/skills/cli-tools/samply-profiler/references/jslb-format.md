# Samply JSLB Format

Read this only when the input is named `.jslb`/`.jslb.gz`, or when `samply load`/`samply import` reports a JSON or perf-data format error. Do not rename the file before checking its bytes.

## Identify the format

Typical symptoms are:

```text
samply import profile.jslb.gz
Error importing perf.data file: LinuxPerf(UnrecognizedMagicValue([31, 139, 8, 8, 0, 0, 0, 0]))

samply load profile.jslb.gz
Could not parse the input file as JSON: expected value at line 1 column 1
If this is a perf.data file, please use `samply import` instead.
```

The first bytes are the gzip header (`0x1f 0x8b`), not a perf-data signature. Inspect the compressed file and its decompressed payload:

```bash
gzip -l profile.jslb.gz
zcat profile.jslb.gz | xxd -l 8
```

A JSLB payload begins with the bytes `dc df 4a 53 4c 42 01 00`; the ASCII `JSLB` is at decompressed offset 2–5. JSLB (JsonSlabs) is a binary profile container associated with `mstange/json-slabs`, not JSON and not `perf.data`.

- `samply import` is for foreign profiler formats such as `perf.data`; its LinuxPerf magic error is the wrong-subcommand symptom.
- `samply load` serves a Firefox Profiler JSON capture in workflows where the selected build expects JSON. A JSON parse error on a confirmed JSLB file means that selected build does not have a JSLB-compatible load path.
- The bundled `scripts/analyze_profile.py` is intentionally JSON-only: it gzip-decompresses and calls `json.loads`, so it cannot analyze JSLB bytes. Use it only after obtaining a Firefox Profiler JSON profile.

## Probe support conditionally

Do not infer JSLB support from a fixed version number, package name, or filename convention. Check the actual executable and source/revision in use:

```bash
command -v samply
samply --version
samply load --help
```

Then try `samply load profile.jslb.gz`. Preserve the result as the capability probe: a JSON parse failure means this executable cannot load the file; a successful local server/browser handoff means it can serve it. If support is uncertain, inspect the selected upstream source revision and test that same binary against the actual file rather than declaring all Samply builds unsupported.

## Use a build with JSLB support

When upstream source inspection shows that the selected revision includes JSLB support, build that revision and retry:

```bash
cargo install --git https://github.com/mstange/samply --branch main samply
~/.cargo/bin/samply load profile.jslb.gz
```

The build can compile hundreds of crates and take several minutes; let it complete or rerun so Cargo can reuse its checkout and artifacts. Verify the executable selected after installation with `command -v samply`, then repeat the capability probe above. Do not describe `main`, any release, or any version as permanently current; support is revision-dependent.

When `samply load` accepts JSLB, Samply serves the raw bytes over its local HTTP server and opens a `profiler.firefox.com/from-url/...` page. JSLB decoding happens in the Firefox Profiler web application. A server route ending in `/profile.json` can still be expected when the served payload is gzip-compressed JSLB; the route name does not establish the payload format.

## Find a newer remote capture

Only do this when the user says a newer profile exists on “the machine”/“the pc” without naming a host and no local file changed. Confirm the reachable Tailscale host before relying on the address. For the workstation convention used by these profiling workflows:

```bash
ssh -o ConnectTimeout=8 not-matthias@100.65.237.101 \
  'find / -xdev -iname "*jslb*" -newermt "-7 days" 2>/dev/null'
```

CodSpeed callgraph captures may be under a monorepo checkout such as `~/work/monorepo/...`; do not treat unrelated `~/projects/*/profile.json.gz` files as JSLB candidates merely because their names are similar. Compare metadata and content before replacing a local file:

```bash
stat -c '%n mtime=%y size=%s' profile.jslb.gz
sha256sum profile.jslb.gz
scp not-matthias@100.65.237.101:/path/to/profile.jslb.gz .
sha256sum profile.jslb.gz
```

Use the exact path and compare both hashes after transfer.
