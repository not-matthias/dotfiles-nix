{user, ...}: {
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "/etc/profiles/per-user/${user}/bin/alacritty";
      exec-arg = "-x";
    };

    # https://askubuntu.com/questions/1272710/how-do-i-enable-tap-to-click-on-my-ubuntu-20-04
    "org/gnome/desktop/peripherals/touchpad" = {
      "tap-to-click" = true;
    };
  };
}
