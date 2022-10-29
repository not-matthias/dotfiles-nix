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

      startup = [
        # https://github.com/NixOS/nixpkgs/issues/119445
        # {command = "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK";}

        {command = "lock";}
        {command = "autotiling";}
        {
          command = "import-gsettings";
          always = true;
        }
        {command = "mako";}
      ];

      bars = [{command = "waybar";}];
      window.border = 0;
      gaps.inner = 20;
    };
  };
}
