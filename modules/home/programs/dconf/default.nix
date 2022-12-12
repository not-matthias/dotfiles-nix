{pkgs, ...}: {
  imports = (import ./extensions);

  # programs.dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "${pkgs.alacritty}/bin/alacritty";
      exec-arg = "-x";
    };

    # https://askubuntu.com/questions/1272710/how-do-i-enable-tap-to-click-on-my-ubuntu-20-04
    "org/gnome/desktop/peripherals/touchpad" = {
      "tap-to-click" = true;
    };

    # Remember mount password
    "org/gnome/shell" = {
      remember-mount-password = true;
      disable-user-extensions = false; # Always enable gnome extensions
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "gnomebedtime@ionutbortis.gmail.com"
        "clipboard-indicator@tudmotu.com"
      ];
      favorite-apps = [
        "firefox.desktop"
        "Alacritty.desktop"
      ];
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
