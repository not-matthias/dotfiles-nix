# Prebuilt ELF RPATH

Use this reference when a prebuilt ELF works in the build sandbox but fails after installation with `error while loading shared objects: libX.so: cannot open shared object file`, especially when the missing library belongs to a bundled library loaded with `dlopen` (for example Electron's `libEGL.so` or `libGLESv2.so`). This is for immutable store packages. A mutable self-updating foreign binary or a system-wide `nix-ld` workaround is a different workflow and must not be substituted here.

## Why a successful build can fail at runtime

The Nix `patchELF` hook runs during `fixupPhase` over ELFs in `$out`. It can:

- convert `DT_RPATH` to `DT_RUNPATH`; and
- shrink the path to libraries directly `NEEDED` by that ELF.

`DT_RUNPATH` is not in the same global lookup scope as `DT_RPATH`. A `dlopen`-loaded bundled library may resolve its own `NEEDED` entries through the caller's global `DT_RPATH`; the hook can therefore break a `$ORIGIN` library set that worked in the upstream distribution. The build log can remain clean because the failing lookup happens only at runtime and only across that loader scope.

## Package-side fix

For an already-linked prebuilt distribution, disable both ELF rewriting and stripping, then set the intended RPATH explicitly in `installPhase`:

```nix
dontPatchELF = true;
dontStrip = true;

nativeBuildInputs = [patchelf];

installPhase = ''
  install -Dm755 <source-binary> $out/libexec/<name>
  patchelf --force-rpath \
    --set-rpath '$ORIGIN:<dir1>:<dir2>...' \
    $out/libexec/<name>
'';
```

`--force-rpath` is essential: plain `patchelf --set-rpath` writes `DT_RUNPATH`. Put `$ORIGIN` first so the application continues to resolve its bundled libraries. Add one path for each required runtime package, commonly `${lib.getLib pkg}/lib` for `stdenv.cc.cc`, glib, GTK, X11 libraries, ALSA, and systemd's `libudev`, according to the actual dependency graph.

Patch every ELF that starts or loads code independently:

- the main application binary;
- separately executed helpers such as `chrome_crashpad_handler`; and
- native add-on `.so` files such as `pixel.node`.

If the artifact is a Bun-compiled executable with data appended after the ELF, do not use this fix: use the interpreter-only Bun procedure in [prebuilt-artifacts.md](prebuilt-artifacts.md), because growing the ELF can corrupt its payload.

## Prove the loader behavior

1. Inspect the dynamic tag, not only its path:

   ```bash
   readelf -d <binary> | grep -E '\((RPATH|RUNPATH)\)'
   ```

   The desired line contains `0x00000000000f (RPATH)`, not `0x1d (RUNPATH)`. `patchelf --print-rpath` prints the path but does not reveal the tag type.

2. Check every ELF in the distribution tree:

   ```bash
   ldd <each-elf>
   ```

   Ordinary direct dependencies should have no `not found` entries. `ldd` on a library loaded only by `dlopen` can report `not found` for dependencies that are available through the caller's global RPATH; that is a loader-scope artifact, not by itself proof of a broken package.

3. Demonstrate the scope case with a minimal caller. Compile a small executable that `dlopen`s the bundled library, give that caller the same forced RPATH, and run it under a clean environment:

   ```bash
   patchelf --force-rpath --set-rpath '<same-rpath>' ./dlopen-probe
   env -i PATH="$PATH" ./dlopen-probe
   ```

   The probe should load the companion library and resolve its transitive dependencies where the direct `ldd` view was misleading.

4. Smoke-run the actual entry point without ambient host paths:

   ```bash
   env -i PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin \
     HOME="$HOME" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
     $out/bin/<name>
   ```

   Adapt the minimal environment to the program's legitimate runtime needs; do not “fix” missing dependencies by inheriting the host's arbitrary `LD_LIBRARY_PATH`.

## Repository-specific notes

`pkgs/terminal-browser.nix` is the reference shape for an Electron distribution: keep the extracted tree, replace the stock `$0`-relative launcher with a `makeWrapper` entry point, and preserve the bundled runtime layout. The host's Nix shim has a few command-line constraints: use a one-line `nix-build --expr` or `nix build --file <expr.nix>` where necessary, and give `nix eval --raw` an explicit file argument. A newly added package file must be staged before a flake build can see it. A no-sudo host package build and the full system toplevel build are distinct checks; switching the system requires separate authorization.
