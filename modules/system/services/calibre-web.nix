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

    services.caddy.virtualHosts."books.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://[::1]:8083
    '';
  };
}
