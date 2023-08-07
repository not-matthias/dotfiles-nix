# References:
# - https://github.com/fufexan/dotfiles/tree/6061b6afc86a883ff9be607bf9c5199c5e4e7bb1/home/programs/eww
# - https://github.com/bazuin-32/dotfiles/blob/main/eww/start.sh
# - https://github.com/fufexan/dotfiles/tree/main
# - https://github.com/b3nj5m1n/dotfiles/blob/53df00e8bafe758c03fd0342ae25c7fbca64081c/nix/modules/nixos/wayland.nix#L15
# - https://github.com/notusknot/dotfiles-nix/blob/a034dcb6daff31ce50cdbc74a5972b1ef56ef3d7/modules/eww/default.nix#L14
# - https://github.com/fufexan/dotfiles/blob/main/home/programs/eww/default.nix
# - https://github.com/saimoomedits/eww-widgets/blob/main/eww/bar
# - https://github.com/elkowar/eww/tree/master/examples/eww-bar
# - https://github.com/elkowar/eww
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
