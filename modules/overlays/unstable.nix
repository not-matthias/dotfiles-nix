# Taken from here: https://github.com/NixOS/nixpkgs/pull/318699#issuecomment-2161730033
{...}: let
  system = "x86_64-linux";

  # Fetch specific version of nixpkgs
  unstabledPkgs =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      sha256 = "sha256:1vc8bzz04ni7l15a9yd1x7jn0bw2b6rszg1krp6bcxyj3910pwb7";
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
