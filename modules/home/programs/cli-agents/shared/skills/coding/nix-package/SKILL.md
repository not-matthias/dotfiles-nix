---
name: nix-package
description: "Creating and debugging Nix packages in dotfiles: fetchers, hashes, overlays, prebuilt artifacts, AppImages, and runtime wrappers."
license: MIT
---

# Nix package creation and debugging

Use this skill when adding or updating a package under `pkgs/`, wiring it into the dotfiles overlay or a host, debugging evaluation/build failures, or packaging an AppImage or other prebuilt artifact.

## Choose the workflow

Start by inspecting the real source or release (`file`, `tar tzf`, `ldd`, and `objdump -p`). Do not infer an artifact's layout or dependencies.

- **Raw ELF, flat tarball, Bun executable, AppImage, Qt GUI, or a source tree that needs writable user state:** follow [references/prebuilt-artifacts.md](references/prebuilt-artifacts.md).
- **A prebuilt ELF fails at runtime after `patchELF`:** follow [references/elf-rpath.md](references/elf-rpath.md), especially for `dlopen`-loaded libraries.
- **Normal source package:** use the generic derivation and wiring workflow below.

The prebuilt references describe immutable packages installed in the Nix store. Do not silently substitute them for mutable self-updating foreign binaries or a `nix-ld` workflow.

## Rapid prototyping

Try dependencies and dynamic linking before writing a full derivation:

```bash
nix-shell -p openssl pkg-config gnumake
nix-shell -p ldd --run "ldd ./my-binary"
nix-shell -p nix-init --run "nix-init https://github.com/user/repo"
```

`nix-init` is a starting point, not a substitute for checking the generated fetcher, metadata, install layout, and runtime dependencies.

## Generic source package

Create `pkgs/<name>.nix` (or `pkgs/<name>/default.nix`) with a real version, source hash, build inputs, and metadata:

```nix
{lib, stdenv, fetchFromGitHub, cmake, ...}:
stdenv.mkDerivation rec {
  pname = "my-tool";
  version = "1.2.3";
  src = fetchFromGitHub {
    owner = "org";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-...";
  };
  nativeBuildInputs = [cmake];
  meta = {
    description = "My tool";
    homepage = "https://github.com/org/repo";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = pname;
  };
}
```

For a URL/tarball package, use `fetchurl` and install the actual program under `$out/bin`. For an AppImage, use the extraction and desktop-entry procedure in the reference rather than guessing filenames.

## Hashes and version updates

For a release asset:

```bash
curl -fsSL -o /tmp/artifact.tar.gz <release-url>
nix hash file /tmp/artifact.tar.gz
```

For an unpacked GitHub source archive:

```bash
nix-prefetch-url --unpack <url> | xargs -I{} nix hash to-sri --type sha256 {}
```

A placeholder SRI hash can be used while drafting; copy Nix's reported hash from the mismatch. Prefer a published checksum when available.

Before updating an existing package, inspect upstream changes. Electron applications may need a new `electron_NN`; removed build dependencies require removing their hooks and inputs; changed source paths require updating `substituteInPlace` targets.

## Overlay and host installation

Register the package in `modules/overlays/pkgs.nix`:

```nix
(_self: super: {
  my-app = super.callPackage ../../pkgs/my-app.nix {};
  # A directory package uses ../../pkgs/my-app instead.
})
```

Then install it explicitly:

```nix
home.packages = with pkgs; [my-app];
# or:
environment.systemPackages = with pkgs; [my-app];
```

The overlay alone does not install a package or create a top-level flake output. A new `pkgs/<name>.nix` must be staged before flakes can see it; already tracked dirty edits remain visible.

## Debugging

Evaluation failures happen before a build:

```bash
sudo nixos-rebuild build --flake .#framework --show-trace
sudo nixos-rebuild build --flake .#framework --option eval-cache false
```

Common causes:

- `attribute 'X' missing`: check overlay registration and `callPackage` arguments.
- `infinite recursion`: use `super`, not `self`, in the overlay.
- `cannot coerce X to string`: check the value's type and string context.

For a package-only build, use an explicit `callPackage` expression rather than `nix build -f` for derivations with arguments:

```bash
nix build --impure --expr \
  'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./pkgs/<name>.nix {}'
```

Missing libraries belong in `buildInputs`; missing build tools belong in `nativeBuildInputs`. For an ELF whose RPATH is broken after fixup, use [references/elf-rpath.md](references/elf-rpath.md) rather than adding arbitrary `LD_LIBRARY_PATH`.

## Unstable packages

Use an explicitly provided unstable package set in modules:

```nix
{pkgs-unstable, ...}: {
  home.packages = [pkgs-unstable.some-package];
}
```

## Completion checklist

- [ ] Source layout, link dependencies, and license were inspected.
- [ ] `pkgs/<name>.nix` has a real hash and `meta.mainProgram` where applicable.
- [ ] Overlay entry points to the package.
- [ ] Package is present in `home.packages` or `environment.systemPackages`.
- [ ] Prebuilt-specific handling follows the applicable reference.
