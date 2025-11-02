{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.dawarich;
  dbName = "dawarich";
  dbUser = "dawarich";
  dbPort = config.services.postgresql.settings.port;
in {
  options.services.dawarich = {
    enable = lib.mkEnableOption "Enable Dawarich location tracking service";
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = [dbName];
      ensureUsers = [
        {
          name = dbUser;
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            superuser = true;
          };
        }
      ];
    };

    services.redis.servers.dawarich = {
      enable = true;
      port = 6380;
      bind = "0.0.0.0";
      settings.protected-mode = "no";
    };

    virtualisation.oci-containers.containers = {
      dawarich-app = {
        image = "freikin/dawarich:latest";
        environment = {
          RAILS_ENV = "production";
          DATABASE_URL = "postgresql://${dbUser}@host.docker.internal:${toString dbPort}/${dbName}";
          REDIS_URL = "redis://host.docker.internal:6380";
          SECRET_KEY_BASE = "your-secret-key-base-change-this-in-production";
          TIME_ZONE = "UTC";
        };
        volumes = [
          "/var/lib/dawarich/app:/var/app"
        ];
        ports = [
          "3002:3000/tcp"
        ];
        extraOptions = [
          "--add-host"
          "host.docker.internal:host-gateway"
        ];
      };
    };

    services.caddy.virtualHosts."dawarich.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:3002
    '';

    services.restic.paths = [
      "/var/lib/dawarich"
    ];

    # Ensure directories exist with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/dawarich 0755 root root -"
      "d /var/lib/dawarich/app 0755 root root -"
    ];
  };
}
