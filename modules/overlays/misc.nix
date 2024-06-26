# Taken from here: https://github.com/NixOS/nixpkgs/pull/318699#issuecomment-2161730033
{...}: let
  # TODO: Find a way to not hardcode this here
  system = "x86_64-linux";

  # Fetch specific version of nixpkgs
  pinnedPkgs =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
      sha256 = "sha256:1i18lq7zlzxx6p9d98lv39zm0abb1f0f4bfqs9vljk3iiirbyj1b";
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
