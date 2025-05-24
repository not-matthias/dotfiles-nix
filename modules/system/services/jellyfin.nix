{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.jellyfin;
in {
  config = lib.mkIf cfg.enable {
    services.jellyfin = {
      # enable = true;
    };
    services.jellyseerr = {
      enable = true;
      port = 5055;
    };

    services.caddy.virtualHosts."jellyfin.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:8096
    '';
    services.caddy.virtualHosts."jellyseerr.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.1:5055
    '';
  };
}
