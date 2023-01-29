{pkgs, ...}: {
  home.packages = with pkgs; [
    newsflash
  ];
}
