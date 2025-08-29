{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.wordpress;
in {
  options.services.wordpress = {
    enable = lib.mkEnableOption "WordPress service";
  };

  config = lib.mkIf cfg.enable {
    services.wordpress = {
      sites."wordpress.${domain}" = {
        database = {
          createLocally = true;
          name = "wordpress";
          user = "wordpress";
        };
        virtualHost = {
          hostName = "localhost";
          listen = [
            {
              ip = "127.0.0.1";
              port = 11439;
            }
          ];
          enableACME = false;
        };
        extraConfig = ''
          # Security headers
          define('FORCE_SSL_ADMIN', false);
          define('WP_HOME', 'https://wordpress.${domain}');
          define('WP_SITEURL', 'https://wordpress.${domain}');

          # Disable file editing
          define('DISALLOW_FILE_EDIT', true);
          define('DISALLOW_FILE_MODS', true);
        '';
      };
    };

    services.caddy.virtualHosts."wordpress.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11439
    '';

    services.restic.paths = ["/var/lib/wordpress"];
  };
}
