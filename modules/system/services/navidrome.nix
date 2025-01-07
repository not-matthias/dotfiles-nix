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

    # Requires /1/ at the end!
    scrobblerUrl = lib.mkOption {
      type = lib.types.str;
      description = "The URL to the ListenBrainz API";
    };
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      package = unstable.navidrome;
      settings = {
        Port = 11424;
        Address = "0.0.0.0";

        ListenBrainz.BaseURL = cfg.scrobblerUrl;
        ListenBrainz.Enabled = cfg.scrobblerUrl != "";
      };
    };

    fileSystems."/var/lib/navidrome/music" = {
      device = cfg.musicFolder;
      options = ["bind" "perms=444"];
    };

    services.caddy.virtualHosts."music.${domain}" = {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:11424
      '';
    };
  };
}
