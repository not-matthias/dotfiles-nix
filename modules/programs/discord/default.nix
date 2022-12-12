{pkgs, ...}: {
  imports = [(import ./betterdiscord.nix)];

  home.packages = with pkgs; [
    discord
    betterdiscordctl
  ];
}
