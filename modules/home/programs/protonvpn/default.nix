# Source: https://github.com/srid/nixos-config/blob/401c51fd35b27fb8ab725f8636dacd7ada4e3da9/nixos/protonvpn.nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    protonvpn-cli
    protonvpn-gui
  ];
}
