{
  config,
  lib,
  unstable,
  user,
  domain,
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
      settings = {
        Port = 11424;
        Address = "127.0.0.1";
        ReverseProxyWhitelist = "127.0.0.1/32";
      };
    };

    fileSystems."/var/lib/navidrome/music" = {
      device = cfg.musicFolder;
      options = ["bind" "perms=444"];
    };

    # FIXME: This doesn't yet work
    services.caddy = {
      virtualHosts."music.${domain}" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy http://127.0.0.1:11424
        '';
        serverAliases = [
          "music.local"
        ];
      };
    };

    #   locations."/".proxyPass = "http://localhost:11424";
    #   locations."/".proxyWebsockets = true;
    # };
  };
}
