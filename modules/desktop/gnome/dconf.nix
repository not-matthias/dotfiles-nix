{lib, ...}:
with lib.hm.gvariant; {
  programs.dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "/usr/bin/env alacritty";
      exec-arg = "-x";
    };
  };
}
