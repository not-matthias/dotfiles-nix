{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.calibre-web;
in {
  config = lib.mkIf cfg.enable {
    services.calibre-web.options = {
      enableBookUploading = true;
      enableKepubify = true;
      enableBookConversion = true;
    };

    # Ensure proper permissions for the Calibre library
    systemd.tmpfiles.rules = [
      "Z /mnt/data/personal/books/calibre-library 0775 calibre-web calibre-web -"
      "Z /mnt/data/personal/books/calibre-library/metadata.db 0664 calibre-web calibre-web -"
    ];

    services.caddy.virtualHosts."books.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://[::1]:8083
    '';
  };
}
