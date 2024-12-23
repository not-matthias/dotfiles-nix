{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.paperless;
in {
  config = lib.mkIf cfg.enable {
    services.paperless = {
      port = 11432;
    };

    services.caddy.virtualHosts."netdata.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11432
    '';
  };
}
