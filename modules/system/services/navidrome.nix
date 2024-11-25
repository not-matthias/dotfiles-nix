{
  config,
  lib,
  unstable,
  user,
  ...
}: let
  cfg = config.services.navidrome;
in {
  options.services.navidrome = {
    musicFolder = lib.mkOption {
      type = lib.types.str;
      default = "/home/${user}/Music/";
      description = "The path to the music folder";
    };
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      package = unstable.navidrome;
      settings.Port = 11424;
      settings.Address = "0.0.0.0";
    };

    fileSystems."/var/lib/navidrome/music" = {
      device = cfg.musicFolder;
      options = ["bind" "perms=444"];
    };

    # services.nginx.enable = true;
    # services.nginx.virtualHosts."navidrome" = {
    #   serverAliases = [
    #     "navidrome.lan"
    #     "music"
    #     "music.lan"
    #     "music.local"
    #   ];

    #   locations."/".proxyPass = "http://localhost:11424";
    #   locations."/".proxyWebsockets = true;
    # };
  };
}
