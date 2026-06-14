{
  config,
  lib,
  pkgs,
  ...
}: let
  dataDirs = [
    "${config.home.homeDirectory}/.local/share"
    "${config.home.homeDirectory}/.nix-profile/share"
    "/etc/profiles/per-user/${config.home.username}/share"
    "/run/current-system/sw/share"
    "/nix/var/nix/profiles/default/share"
  ];

  initialConfig = pkgs.writeText "vicinae.json" (builtins.toJSON {
    rootSearch.searchFiles = false;
  });
in {
  stylix.targets.vicinae.enable = false;

  programs.vicinae = {
    enable = true;
    settings = lib.mkForce {};
    systemd = {
      enable = true;
      autoStart = true;
    };
  };

  systemd.user.services.vicinae.Service.Environment = [
    "XDG_DATA_DIRS=${builtins.concatStringsSep ":" dataDirs}"
  ];

  home.activation.vicinaeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    config_dir="${config.xdg.configHome}/vicinae"
    config_file="$config_dir/vicinae.json"

    mkdir -p "$config_dir"
    if [ -L "$config_file" ] || [ ! -e "$config_file" ]; then
      rm -f "$config_file"
      cp ${initialConfig} "$config_file"
      chmod u+w "$config_file"
    fi
  '';
}
