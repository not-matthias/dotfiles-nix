{pkgs, ...}: {
  home.packages = [
    pkgs.alacritty
    pkgs.wofi
    pkgs.waybar
  ];

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    config = {
      terminal = "alacritty";
      menu = "wofi --show run";

      # TODO: https://github.com/KubqoA/dotfiles/blob/main/modules/desktop/swaywm.nix

      bars = [{command = "waybar";}];
      # swaymsg gaps inner all set 20
      gaps.inner = 20;

      input = {};

      startup = [
        {command = "lock";}
        {command = "autotiling";}
        {command = "mako";}
      ];
    };
  };
}
