{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.vikunja-app;
  port = 3456;
in {
  options.services.vikunja-app = {
    enable = lib.mkEnableOption "Enable Vikunja";
  };

  config = lib.mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      port = port;
      frontendScheme = "https";
      frontendHostname = "vikunja.${domain}";
      database.type = "sqlite";
      settings = {
        service = {
          enableregistration = false;
          timezone = "Europe/Vienna";
        };
      };
    };

    services.caddy.virtualHosts."vikunja.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString port}
    '';

    services.restic.paths = ["/var/lib/vikunja"];
  };
}
