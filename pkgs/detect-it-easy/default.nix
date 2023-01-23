# Build with: nix build -f default.nix
# See: https://nixos.wiki/wiki/Appimage
{pkgs ? import <nixpkgs> {}}: let
  version = "3.07";
in
  pkgs.appimageTools.wrapType2 {
    name = "detect-it-easy";
    src = pkgs.fetchurl {
      url = "https://github.com/horsicq/DIE-engine/releases/download/${version}/Detect_It_Easy-${version}-x86_64.AppImage";
      sha256 = "9rr9oq2YQngN6EshFRu71/Qlle9fyjDL2yUWYrg1NwI=";
    };
  }
