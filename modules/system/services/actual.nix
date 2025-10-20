{
  unstable,
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.actual;
in {
  config = lib.mkIf cfg.enable {
    services.actual = {
      package = unstable.actual-server;
      settings = {
        port = 5006;
      };
    };

    # Add Caddy reverse proxy configuration for Actual Budget
    services.caddy.virtualHosts."actual.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:5006
    '';

    # Optional: Add to restic backups
    services.restic.paths = ["/var/lib/actual"];
  };
}
