# Taken from here: https://github.com/NixOS/nixpkgs/pull/318699#issuecomment-2161730033
{...}: let
  # TODO: Find a way to not hardcode this here
  system = "x86_64-linux";

  # Fetch specific version of nixpkgs
  pinnedPkgs =
    import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz";
      sha256 = "sha256:0bpw6x46mp0xqfdwbrhnjn6qlb4avglir993n3cdqg8zv4klgllw";
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
