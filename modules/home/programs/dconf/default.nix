{pkgs, ...}: {
  imports = import ./extensions;

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

    "org/gnome/desktop/wm/keybindings" = {
      move-to-workspace-1 = ["<Shift><Alt>1"];
      move-to-workspace-2 = ["<Shift><Alt>2"];
      move-to-workspace-3 = ["<Shift><Alt>3"];
      move-to-workspace-4 = ["<Shift><Alt>4"];
      switch-to-workspace-1 = ["<Alt>1"];
      switch-to-workspace-2 = ["<Alt>2"];
      switch-to-workspace-3 = ["<Alt>3"];
      switch-to-workspace-4 = ["<Alt>4"];
    };

    # Dark theme
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-light";
    };

    # Center new windows
    "org/gnome/mutter" = {
      center-new-windows = true;
    };
  };
}
