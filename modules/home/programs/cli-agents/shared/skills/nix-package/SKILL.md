---
name: nix-package
description: Creating and debugging Nix packages - fetchers, hash generation, overlays, AppImage wrapping, and common build patterns for NixOS dotfiles.
license: MIT
---

# Nix Package Creation & Debugging

Guide for creating custom Nix packages, debugging build failures, and integrating packages into a NixOS overlay.

## When to Use This Skill

- Creating a new package in `pkgs/`
- Updating a package version (hash mismatch)
- Debugging eval errors or build failures
- Wrapping an AppImage or prebuilt binary
- Adding a package to the overlay

## Adding a New Package

### Step 1: Create `pkgs/<name>/default.nix` (or `pkgs/<name>.nix`)

#### URL/Tarball (prebuilt binary)
```nix
{lib, stdenv, fetchurl, ...}: let
  pname = "my-app";
  version = "1.2.3";
in stdenv.mkDerivation {
  inherit pname version;
  src = fetchurl {
    url = "https://example.com/my-app-${version}.tar.gz";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp my-app $out/bin/
    chmod +x $out/bin/my-app
  '';
  meta = {
    description = "My application";
    homepage = "https://example.com";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "my-app";
  };
}
```

#### AppImage
```nix
{lib, appimageTools, fetchurl}: let
  pname = "my-app";
  version = "1.2.3";
  src = fetchurl {
    url = "https://example.com/my-app-${version}.AppImage";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
in appimageTools.wrapType2 {
  inherit pname version src;
  meta = {
    description = "My application";
    homepage = "https://example.com";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = pname;
  };
}
```

#### GitHub Source
```nix
{lib, stdenv, fetchFromGitHub, cmake, ...}: stdenv.mkDerivation rec {
  pname = "my-tool";
  version = "1.2.3";
  src = fetchFromGitHub {
    owner = "org";
    repo = "repo";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
  nativeBuildInputs = [cmake];
  meta = {
    description = "My tool";
    homepage = "https://github.com/org/repo";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
```

### Step 2: Register in overlay (`modules/overlays/pkgs.nix`)

```nix
(_self: super: {
  my-app = super.callPackage ../../pkgs/my-app.nix {};
  # For subdirectory packages:
  my-app = super.callPackage ../../pkgs/my-app {};
})
```

### Step 3: Add to host config

```nix
home.packages = with pkgs; [my-app];
# or system-wide:
environment.systemPackages = with pkgs; [my-app];
```

## Getting Hashes

**Start with a fake hash — Nix will tell you the real one:**

```nix
hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
```

Build fails with: `hash mismatch ... got: sha256-<actual>` — copy that value.

```bash
# Prefetch before writing the package
nix-prefetch-url --type sha256 <url>
# Convert hex → SRI: nix hash to-sri --type sha256 <hex>

# For GitHub
nix-prefetch-fetchFromGitHub --owner <org> --repo <repo> --rev <tag>
```

## Debugging Build Failures

### Eval errors (before build)

```bash
sudo nixos-rebuild build --flake .#framework --show-trace
# Cached failure? Force re-eval:
sudo nixos-rebuild build --flake .#framework --option eval-cache false
```

Common eval errors:
- `attribute 'X' missing` → Check overlay registration or callPackage args
- `infinite recursion` → Use `super` not `self` in overlay
- `cannot coerce X to string` → Wrong type passed to a string context

### Build errors (during build)

```bash
# Build single package in isolation
nix build -f pkgs/<name>.nix
nix-build pkgs/<name>.nix

# Interactive build env
nix develop .#<derivation>
```

Common build errors:
- Missing library → add to `buildInputs`
- Missing build tool → add to `nativeBuildInputs`
- Prebuilt binary RPATH issues:
  ```nix
  nativeBuildInputs = [patchelf autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib zlib];
  ```

## Using Unstable Packages

```nix
# In a module
{pkgs-unstable, ...}: {
  home.packages = [pkgs-unstable.some-package];
}
```

## Checklist for New Package

- [ ] `nix build -f pkgs/<name>.nix` succeeds
- [ ] Overlay entry in `modules/overlays/pkgs.nix`
- [ ] Added to `home.packages` or `environment.systemPackages`
- [ ] `sudo nixos-rebuild build --flake .#framework` succeeds
- [ ] `meta.mainProgram` set for executables
- [ ] License set (`lib.licenses.unfree` for proprietary)
