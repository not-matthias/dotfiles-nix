# Taken from here: https://github.com/NixOS/nixpkgs/pull/318699#issuecomment-2161730033
{...}: let
  system = "x86_64-linux";

  # Fetch specific version of nixpkgs
  unstabledPkgs =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      sha256 = "sha256:1ds3yjcy52l8d3rkxr3b7h9c0c3nly079bgakjaasnfjj3xprrwr";
    }) {
      inherit system;

      config = {
        allowUnfree = true;
      };
    };
in {
  nixpkgs.config = {
    packageOverrides = pkgs:
      with pkgs; {
        unstable = import unstabledPkgs {
          config = config.nixpkgs.config;
        };
      };
  };

  nixpkgs.overlays = [
    (_final: _prev: {
      # Override packages with pinned nixpkgs
      zed-editor = unstabledPkgs.zed-editor;
    })
  ];
}
