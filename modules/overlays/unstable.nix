# Taken from here: https://github.com/NixOS/nixpkgs/pull/318699#issuecomment-2161730033
{...}: let
  system = "x86_64-linux";

  # Fetch specific version of nixpkgs
  unstabledPkgs =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
      sha256 = "sha256:0g0m7zhpnbgzwn4gmqhjvqd9v6d917p1dg3fk1kwxs2x7v7c1zd4";
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
