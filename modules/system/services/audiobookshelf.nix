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
    audioFolder = lib.mkOption {
      type = lib.types.str;
      description = "The path to the audio folder";
    };
  };

  config = lib.mkIf cfg.enable {
    services.audiobookshelf = {
      package = unstable.audiobookshelf;
      host = "0.0.0.0";
      port = 8234;
    };

    fileSystems."/var/lib/audiobookshelf/media" = {
      device = cfg.audioFolder;
      options = ["bind" "perms=444"];
    };

    services.caddy.virtualHosts."audiobooks.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:8234
    '';
  };
}
