{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.immich;
in {
  config = lib.mkIf cfg.enable {
    services.immich = {
      port = 2283;
      database.enable = true;
      redis.enable = true;
      machine-learning.enable = true;
      machine-learning.environment = {};
      # TODO:
      # mediaLocation = "/data/images";
      secretsFile = null;
      settings.server.externalDomain = "https://${config.hostnames.photos}";
      environment = {
        IMMICH_ENV = "production";
        IMMICH_LOG_LEVEL = "log";
        NO_COLOR = "false";
        IMMICH_TRUSTED_PROXIES = "127.0.0.1";
      };
    };

    services.caddy.virtualHosts."photo.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11432
    '';
  };
}
