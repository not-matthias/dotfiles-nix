{
  pkgs,
  user,
  ...
}: {
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "${pkgs.alacritty}/bin/alacritty";
      exec-arg = "-x";
    };

    # https://askubuntu.com/questions/1272710/how-do-i-enable-tap-to-click-on-my-ubuntu-20-04
    "org/gnome/desktop/peripherals/touchpad" = {
      "tap-to-click" = true;
    };

    # Screenshot via Ctrl+Alt+s
    "org/gnome/shell/keybindings" = {
      "show-screenshot-ui" = ["<Shift><Alt>s"];
    };

    # Custom keybinds
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Primary><Alt>t";
      command = "alacritty";
      name = "open-terminal";
    };

    # Dark theme
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    # Center new windows
    "org/gnome/mutter" = {
      center-new-windows = true;
    };
  };
}
