# References:
# - https://github.com/fufexan/dotfiles/tree/6061b6afc86a883ff9be607bf9c5199c5e4e7bb1/home/programs/eww
{pkgs, ...}: {
  home.packages = with pkgs; [
    eww-wayland
    pamixer
    brightnessctl
    (nerdfonts.override {fonts = ["JetBrainsMono"];})
  ];

  xdg.configFile."eww" = {
    source = ./bar;
    recursive = true;
    # onChange = reload_script;
  };
}
