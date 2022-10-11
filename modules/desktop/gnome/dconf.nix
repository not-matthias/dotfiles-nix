{programs, ...}: {
  programs.dconf.enable = true;

  dconf.settings = {
    "system/locale" = {
      region = "en_US.UTF-8";
    };
  };
}
# {lib, ...}: {
#   dconf.settings = {
#     # "org/gnome/desktop/applications/terminal" = {
#   #     exec = "/usr/bin/env alacritty";
#   #     exec-arg = "-x";
#     # };
#   };
# }

