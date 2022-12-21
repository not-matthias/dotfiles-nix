{pkgs ? import <nixpkgs> {}}:
pkgs.libsForQt5.callPackage ./default.nix {}
