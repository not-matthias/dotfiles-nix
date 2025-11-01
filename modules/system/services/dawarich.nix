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

    virtualisation.oci-containers.containers = {
      dawarich-redis = {
        image = "redis:7.4-alpine";
        volumes = [
          "/var/lib/dawarich/redis:/data"
        ];
        extraOptions = [
          "--network=dawarich"
        ];
      };

      dawarich-app = {
        image = "freikin/dawarich:latest";
        environment = {
          RAILS_ENV = "production";
          DATABASE_URL = "postgresql://${dbUser}@host.docker.internal:${toString dbPort}/${dbName}";
          REDIS_URL = "redis://dawarich-redis:6379/0";
          SECRET_KEY_BASE = "your-secret-key-base-change-this-in-production";
          TIME_ZONE = "UTC";
        };
        volumes = [
          "/var/lib/dawarich/app:/var/app"
        ];
        ports = [
          "3000:3000/tcp"
        ];
        dependsOn = [
          "dawarich-redis"
        ];
        extraOptions = [
          "--network=dawarich"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };
    };

    # Create custom network for Dawarich containers
    systemd.services.init-dawarich-network = {
      description = "Create Dawarich Docker network";
      wantedBy = ["multi-user.target"];
      before = ["docker-dawarich-redis.service" "docker-dawarich-app.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "${config.virtualisation.oci-containers.backend} network create dawarich || true";
      };
    };

    services.caddy.virtualHosts."dawarich.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:3000
    '';

    services.restic.paths = [
      "/var/lib/dawarich"
    ];

    # Ensure directories exist with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/dawarich 0755 root root -"
      "d /var/lib/dawarich/redis 0755 root root -"
      "d /var/lib/dawarich/app 0755 root root -"
    ];
  };
}
