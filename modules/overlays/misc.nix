# Taken from here: https://github.com/NixOS/nixpkgs/pull/318699#issuecomment-2161730033
{...}: let
  # TODO: Find a way to not hardcode this here
  system = "x86_64-linux";

  # Fetch specific version of nixpkgs
  pinnedPkgs =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
      sha256 = "sha256:0w21qcdk79dmnz0ijbx4mlxbks835nbzfmn0bm1jhx9d0cfj4wr1";
    }) {
      inherit system;

      config = {
        allowUnfree = true;
      };
    };
in {
  nixpkgs.overlays = [
    (_final: _prev: {
      # Override packages with pinned nixpkgs
      obsidian = pinnedPkgs.obsidian;
    })
  ];
}
