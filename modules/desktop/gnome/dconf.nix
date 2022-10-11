{lib, ...}:
with lib.hm.gvariant; {
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "/usr/bin/env alacritty";
      exec-arg = "-x";
    };
  };
}
