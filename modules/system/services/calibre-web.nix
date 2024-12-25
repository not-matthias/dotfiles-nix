{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.calibre-web;
in {
  config = lib.mkIf cfg.enable {
    services.calibre-web = {
      listen.port = 11419;
      # dataDir = "/mnt/data/personal/books";
      options = {
        enableBookUploading = true;
        enableBookConversion = true;
      };
    };

    services.caddy.virtualHosts."books.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11419
    '';

    # TODO: Backup with restic
  };
}
