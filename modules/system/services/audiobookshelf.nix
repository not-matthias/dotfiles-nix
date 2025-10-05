{
  unstable,
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.audiobookshelf;
in {
  options.services.audiobookshelf = {
    audiobookFolder = lib.mkOption {
      type = lib.types.str;
      description = "The path to the audiobook folder";
    };
    podcastFolder = lib.mkOption {
      type = lib.types.str;
      description = "The path to the podcast folder";
    };
  };

  config = lib.mkIf cfg.enable {
    services.audiobookshelf = {
      package = unstable.audiobookshelf;
      host = "0.0.0.0";
      port = 8234;
    };

    fileSystems."/var/lib/audiobookshelf/audiobooks" = {
      device = cfg.audiobookFolder;
      options = ["bind" "perms=444"];
    };

    fileSystems."/var/lib/audiobookshelf/podcasts" = {
      device = cfg.podcastFolder;
      options = ["bind" "perms=444"];
    };

    systemd.tmpfiles.rules = [
      "Z ${cfg.audiobookFolder} - audiobookshelf audiobookshelf - -"
      "Z ${cfg.podcastFolder} - audiobookshelf audiobookshelf - -"
    ];

    services.caddy.virtualHosts."audiobooks.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:8234
    '';
  };
}
