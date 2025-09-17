{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.dawarich;
in {
  options.services.dawarich = {
    enable = lib.mkEnableOption "Enable Dawarich location tracking service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      dawarich-redis = {
        image = "redis:7.0-alpine";
        volumes = [
          "/var/lib/dawarich/redis:/data"
        ];
        extraOptions = [
          "--network=dawarich"
        ];
      };

      dawarich-db = {
        image = "postgres:14.2-alpine";
        environment = {
          POSTGRES_DB = "dawarich";
          POSTGRES_USER = "dawarich";
          POSTGRES_PASSWORD = "dawarich";
        };
        volumes = [
          "/var/lib/dawarich/postgres:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=dawarich"
        ];
      };

      dawarich-app = {
        image = "freikin/dawarich:latest";
        environment = {
          RAILS_ENV = "production";
          DATABASE_URL = "postgresql://dawarich:dawarich@dawarich-db:5432/dawarich";
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
          "dawarich-db"
          "dawarich-redis"
        ];
        extraOptions = [
          "--network=dawarich"
        ];
      };
    };

    # Create custom network for Dawarich containers
    systemd.services.init-dawarich-network = {
      description = "Create Dawarich Docker network";
      wantedBy = ["multi-user.target"];
      before = ["docker-dawarich-db.service" "docker-dawarich-redis.service" "docker-dawarich-app.service"];
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
      "d /var/lib/dawarich/postgres 0755 root root -"
      "d /var/lib/dawarich/redis 0755 root root -"
      "d /var/lib/dawarich/app 0755 root root -"
    ];
  };
}
