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
      settings = {
        server = {
          HTTP_HOST = "0.0.0.0";
          HTTP_PORT = 11430;

          ROOT_URL = "https://git.${domain}";
          DOMAIN = "git.${domain}";
        };
        service = {
          DISABLE_REGISTRATION = true;
          REQUIRE_SIGNIN_VIEW = true;
        };
      };
    };

    services.caddy.virtualHosts."git.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11430
    '';

    services.restic.paths = ["/var/lib/gitea"];
  };
}
