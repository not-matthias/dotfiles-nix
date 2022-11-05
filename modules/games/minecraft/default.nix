{pkgs, ...}: {
  home.packages = with pkgs; [
    minecraft
    fabric-installer
  ];
}
