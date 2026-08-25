{config, ...}: let
  dataDirs = [
    "${config.home.homeDirectory}/.local/share"
    "${config.home.homeDirectory}/.nix-profile/share"
    "/etc/profiles/per-user/${config.home.username}/share"
    "/run/current-system/sw/share"
    "/nix/var/nix/profiles/default/share"
  ];
in {
  stylix.targets.vicinae.enable = false;

  programs.vicinae = {
    enable = true;
    settings = {
      search_files_in_root = false;
      providers.files.preferences.autoIndexing = false;
    };
    systemd = {
      enable = true;
      autoStart = true;
    };
  };

  systemd.user.services.vicinae.Service.Environment = [
    "XDG_DATA_DIRS=${builtins.concatStringsSep ":" dataDirs}"
  ];
}
