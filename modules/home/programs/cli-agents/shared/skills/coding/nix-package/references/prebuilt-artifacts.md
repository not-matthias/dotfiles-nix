# Prebuilt artifacts

Use this reference when the upstream release is an artifact rather than source that should be built by Nix. The package still lives in `pkgs/`, is exposed through the overlay, and is installed by a host or home-manager module. Do not silently apply this workflow to a mutable, self-updating foreign binary or to a binary intended to be found through `nix-ld`; those are separate workflows.

## Choose the artifact shape first

| Release shape | Derivation approach |
| --- | --- |
| One raw ELF per architecture | `dontUnpack`, install the file, then `autoPatchelfHook` |
| Flat `.tar.gz` with no top directory | `dontUnpack`, extract manually in `installPhase`, then let `autoPatchelfHook` patch `$out` |
| Bun `bun build --compile` executable | Patch only the interpreter; never run `autoPatchelfHook` |
| AppImage | `appimageTools.wrapType2`, after extracting it to inspect the payload |
| Qt5 GUI tarball with bundled Qt | `autoPatchelfHook` plus `makeWrapper` for Qt plugin paths |
| Script plus source tree that writes user state beside itself | Seed a writable user-home copy from the store tree |

Never infer the layout. Inspect the real release before writing the derivation:

```bash
tar tzf artifact.tar.gz
file artifact-or-binary
ldd artifact-or-binary
objdump -p artifact-or-binary | grep -E 'NEEDED|RPATH|RUNPATH'
```

## Hashes and fetchers

Download the exact release asset and generate an SRI hash:

```bash
curl -fsSL -o /tmp/artifact.tar.gz <release-url>
nix hash file /tmp/artifact.tar.gz
```

For a `fetchFromGitHub` version bump, prefetch the unpacked archive and convert the result when needed:

```bash
nix-prefetch-url --unpack <url> | xargs -I{} nix hash to-sri --type sha256 {}
```

Check a published `SHA256SUMS` file against the downloaded asset. A placeholder hash is useful only while developing a derivation: Nix will report the actual hash in the mismatch error.

## Raw ELF and flat tarballs

A flat archive makes the default unpack phase fail because it produces no directory. Extract it yourself; `autoPatchelfHook` still sees ELF files installed under `$out` during fixup.

```nix
{lib, stdenv, fetchurl, autoPatchelfHook, gnutar}:
stdenv.mkDerivation rec {
  pname = "<name>";
  version = "<VERSION>";
  src = fetchurl {
    url = "https://github.com/<owner>/<repo>/releases/download/v${version}/<asset>.tar.gz";
    hash = "sha256-...=";
  };
  dontUnpack = true;
  dontStrip = true; # preserve upstream prebuilt binaries
  nativeBuildInputs = [autoPatchelfHook gnutar];
  buildInputs = [stdenv.cc.cc.lib];
  installPhase = ''
    runHook preInstall
    tar xzf "$src"
    install -Dm755 <asset>.bin "$out/bin/<name>"
    runHook postInstall
  '';
  meta = {
    description = "...";
    homepage = "https://github.com/<owner>/<repo>";
    downloadPage = "https://github.com/<owner>/<repo>/releases";
    license = lib.licenses.<license>;
    platforms = ["x86_64-linux"];
    mainProgram = "<name>";
  };
}
```

Inspect dependencies before choosing `buildInputs`: a binary whose `ldd` output is only glibc/libgcc normally needs `stdenv.cc.cc.lib`. A `static-pie linked` binary needs `stdenvNoCC.mkDerivation`, `fetchurl`, and no `autoPatchelfHook`. If a release ships a launcher script only to set `LD_LIBRARY_PATH` for non-Nix systems, install the real binary instead. Use `stdenvNoCC.hostPlatform.system` when the derivation receives `stdenvNoCC`; a bare `stdenv` name is not implicitly available.

A plain `home.packages` entry is the default. Add a dedicated module only when the program needs configuration or runtime wrapping.

## Bun-compiled executables

A Bun standalone release is usually one large, extensionless, dynamically linked ELF per architecture. Bun appends JavaScript resources after the ELF structure. Growing or rewriting its ELF with `patchelf --set-rpath` can corrupt the appended payload, so do not use `autoPatchelfHook`; stripping is unsafe for the same reason.

```nix
{lib, stdenv, stdenvNoCC, fetchurl, patchelf, makeWrapper, git}:
let
  version = "X.Y.Z";
  platforms = {
    x86_64-linux = {path = "linux-x64"; hash = "sha256-...";};
    aarch64-linux = {path = "linux-arm64"; hash = "sha256-...";};
  };
  platform = platforms.${stdenvNoCC.hostPlatform.system}
    or (throw "<name>: unsupported system ${stdenvNoCC.hostPlatform.system}");
in stdenvNoCC.mkDerivation {
  pname = "<name>";
  inherit version;
  src = fetchurl {
    url = "https://github.com/<owner>/<repo>/releases/download/v${version}/<name>-${platform.path}";
    inherit (platform) hash;
  };
  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;
  nativeBuildInputs = [patchelf makeWrapper];
  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/libexec/<name>"
    patchelf --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
      "$out/libexec/<name>"
    makeWrapper "$out/libexec/<name>" "$out/bin/<name>" \
      --prefix PATH : ${lib.makeBinPath [git]}
    runHook postInstall
  '';
  meta = with lib; {
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    mainProgram = "<name>";
    platforms = builtins.attrNames platforms;
  };
}
```

`stdenvNoCC.mkDerivation` is intentional, but `${stdenv.cc}/nix-support/dynamic-linker` is still the repository convention for obtaining the Nix glibc interpreter. Add only runtime commands absent from the normal user `PATH` to `makeWrapper` (for example `git` for a review tool, or `ripgrep`/`xdg-utils` where required). Check the result with `patchelf --print-interpreter`, the program's version command, and a search for the expected `/nix/store/...-git` wrapper path. Identify the license from the upstream repository rather than guessing.

## AppImages

Extract first. The real desktop filename, icon basename, `Exec=`, and MIME declarations vary, especially for Electron AppImage-builder output:

```bash
mkdir -p /tmp/pkg-extract
cd /tmp/pkg-extract
curl -fsSL -o app.AppImage <release-url>
chmod +x app.AppImage
./app.AppImage --appimage-extract >/dev/null 2>&1
find squashfs-root -name '*.desktop' -exec cat {} \;
find squashfs-root -path '*icons/hicolor*' -name '*.png'
grep -E 'BIN=|exec' squashfs-root/AppRun
```

Use `appimageTools.wrapType2` for the derivation. Set the desktop file and icon names from the extracted files, not from a guessed upstream convention. If the wrapped output is available as `appimageContents`, install the desktop entry under the package name and substitute both executable and icon references:

```nix
extraInstallCommands = ''
  install -Dm444 ${appimageContents}/<RealName>.desktop \
    "$out/share/applications/<pkg-name>.desktop"
  substituteInPlace "$out/share/applications/<pkg-name>.desktop" \
    --replace-fail "Exec=AppRun ..." "Exec=$out/bin/<pkg-name> ..." \
    --replace-fail "Icon=<RealName>" "Icon=<pkg-name>"
  install -Dm444 ${appimageContents}/usr/share/icons/hicolor/<SIZE>/apps/<RealName>.png \
    "$out/share/icons/hicolor/<SIZE>/apps/<pkg-name>.png"
'';
```

Preserve `MimeType=`, install every icon size present upstream, and use `lib.licenses.unfree` for closed-source applications. Do not copy a license value from another package. Inspect the final desktop file, icon tree, and executable path.

## Qt5 GUI tarballs

Inspect the archive and bundled plugin dependencies before writing `buildInputs`:

```bash
tar tzf app.tar.gz | grep -viE 'Documentation/' | sort
file <bin>
objdump -p <bin> | grep -E 'NEEDED|RUNPATH'
objdump -p Qt/plugins/platforms/libqxcb.so | grep NEEDED
```

A single top-level directory means `unpackPhase` enters it; copy `./.` rather than repeating the top directory in `installPhase`. Use `autoPatchelfHook` for the ELF tree, but provide system libraries needed by the bundled Qt platform plugin rather than bundled Qt itself. Typical dependencies include:

```nix
(lib.getLib stdenv.cc.cc) zlib (lib.getLib elfutils) glib fontconfig
freetype dbus libGL libxkbcommon gtk3 gdk-pixbuf pango cairo atk
libx11 libxext libxcb libxrender
libxcb-util libxcb-image libxcb-keysyms libxcb-render-util libxcb-wm
```

Use current top-level attributes (`libx11`, `libxcb-util`, `libxcb-image`, `libxcb-keysyms`, `libxcb-render-util`, `libxcb-wm`) rather than deprecated `xorg.*` names. `(lib.getLib elfutils)` supplies `libelf.so.1`, a common missing dependency.

Copy the tree to `$out/opt/<name>` and wrap each entry binary. Without `qt.conf`, set both plugin variables:

```bash
makeWrapper $out/opt/<name>/<GuiBin> $out/bin/<name> \
  --set QT_PLUGIN_PATH $out/opt/<name>/Qt/plugins \
  --set QT_QPA_PLATFORM_PLUGIN_PATH $out/opt/<name>/Qt/plugins/platforms
```

Use `lib.licenses.unfree`, `sourceProvenance = [lib.sourceTypes.binaryNativeCode]`, `mainProgram`, and an explicit platform list where appropriate. Check both the main executable and `Qt/plugins/platforms/libqxcb.so` for unresolved libraries, then exercise a command-line/help entry point.

## Source tree that must be writable

Use this only when the entry point is a script that needs sibling files and writes user state into its self-located directory. Confirm by reading the repository root and installer, checking whether the Python entry point is merely a shell shim, and locating writes based on `BASH_SOURCE`, `$0`, or a derived home directory.

Package the immutable defaults under `$out/share/<tool>`, then seed a writable `$TOOL_HOME` on first run or version change. `dontPatchShebangs = true` is needed when helper scripts execute inside containers or use `env -S` shebangs; invoke the host entry point with `bash` from the wrapper instead.

```nix
stdenv.mkDerivation rec {
  pname = "<tool>";
  version = "<ver>";
  src = fetchFromGitHub {owner = "..."; repo = "..."; rev = "v${version}"; hash = "sha256-...=";};
  dontBuild = true;
  dontPatchShebangs = true;
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/share/<tool> $out/bin
    cp -r . $out/share/<tool>/
    chmod -R u+w $out/share/<tool>
    cat > $out/bin/<tool> <<'WRAPPER'
#!/usr/bin/env bash
set -e
TOOL_HOME="''${TOOL_HOME:-$HOME/.<tool>}"
NIX_VERSION="@version@"
if [ ! -f "$TOOL_HOME/<entry>.sh" ] || [ "$(cat "$TOOL_HOME/.nix-version" 2>/dev/null)" != "$NIX_VERSION" ]; then
  mkdir -p "$TOOL_HOME"
  _bak="$(mktemp -d)"
  preserve_files=("$TOOL_HOME"/services/*/override.env)
  for source in "${preserve_files[@]}"; do
    [ -f "$source" ] || continue
    relative="${source#"$TOOL_HOME"/}"
    mkdir -p "$_bak/$(dirname "$relative")"
    cp -a "$source" "$_bak/$relative"
  done
  cp -r "@out@/share/<tool>/." "$TOOL_HOME/"
  if [ -d "$_bak" ]; then
    cp -a "$_bak/." "$TOOL_HOME/"
  fi
  rm -rf "$_bak"
  chmod -R u+w "$TOOL_HOME"
  echo "$NIX_VERSION" > "$TOOL_HOME/.nix-version"
fi
exec bash "$TOOL_HOME/<entry>.sh" "$@"
WRAPPER
    chmod +x $out/bin/<tool>
    substituteInPlace $out/bin/<tool> --subst-var out --subst-var version
  '';
  postFixup = ''wrapProgram $out/bin/<tool> --prefix PATH : ${lib.makeBinPath [ /* runtime CLIs */ ]}'';
}
```

Gitignored user files such as `.env`, saved profiles, and caches are absent from the store tree and survive a copy. Tracked defaults that users edit do not survive a plain `cp -r`; back them up and restore them, mirroring the upstream installer. A real preservation check must cover both categories and confirm that new upstream defaults are refreshed. Keep this user-state seeding workflow distinct from mutable foreign self-updaters.

## Non-nixpkgs Chromium forks in Home Manager

Home Manager's Chromium module may call `.override`, which AppImage-derived packages do not provide. Bake flags into a wrapper and set `commandLineArgs = []` rather than passing flags through the module:

```nix
thoriumWrapped = pkgs.runCommandLocal "thorium-wrapped" {
  nativeBuildInputs = [pkgs.makeWrapper];
} ''
  mkdir -p $out/bin
  makeWrapper ${thorium}/bin/thorium $out/bin/thorium \
    --add-flags "--no-default-browser-check --disable-breakpad"
  ln -s ${thorium}/share $out/share
'';
```

If the module's `dictionaries` path expects `passthru.dictFileName`, use the Chromium dictionary set or drop the optional field; ordinary `hunspellDicts.en_US` does not necessarily provide it. Extension management works only if the fork reads the profile directory Home Manager populates. Confirm the actual launch command and Profile Path in `chrome://version`; a package that adds `--user-data-dir=~/.config/<fork>` will not read extensions placed under `~/.config/chromium`.

## Overlay, host wiring, and flake visibility

A package is not installed merely by existing under `pkgs/`. Wire all three locations:

```nix
# modules/overlays/pkgs.nix
(_self: super: {
  <name> = super.callPackage ../../pkgs/<name>.nix {};
})
```

Then add `pkgs.<name>` to the host's `home-manager.users.<user>.home.packages` list or to `environment.systemPackages`. A newly created package file must be staged before flakes can see it; dirty edits to an already tracked file remain visible.

Do not assume the overlay creates a top-level flake output. Package visibility is through the host's package set. For a package-specific check, use the host attribute or an isolated `callPackage` expression; activation (`nixos-rebuild switch`) is a separate, explicitly authorized operation.
