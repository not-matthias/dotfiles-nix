{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.gitea;
in {
  config = lib.mkIf cfg.enable {
    services.gitea = {
      settings.server.HTTP_HOST = "0.0.0.0";
      settings.server.HTTP_PORT = 11430;
    };

    services.caddy.virtualHosts."git.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11430
    '';
  };
}
