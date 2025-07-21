{
  lib,
  config,
  domain,
  pkgs,
  ...
}: let
  cfg = config.services.twenty;
  dataDir = "/var/lib/twenty";
in {
  options.services.twenty = {
    enable = lib.mkEnableOption "Twenty CRM service";
  };

  config = lib.mkIf cfg.enable {
    # Create data directories
    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/db 0755 70 70 -"
      "d ${dataDir}/storage 0755 1000 1000 -"
    ];

    # Create network for containers
    systemd.services.init-twenty-network = {
      description = "Create twenty-network";
      after = ["docker.service"];
      wants = ["docker.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker network inspect twenty-network >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create twenty-network
      '';
    };

    virtualisation.oci-containers.containers = {
      twenty-db = {
        image = "postgres:16.8-alpine";
        volumes = ["${dataDir}/db:/var/lib/postgresql/data"];
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
        };
        extraOptions = [
          "--network=twenty-network"
          "--network-alias=twenty-db"
        ];
      };

      twenty-redis = {
        image = "redis:8.0.2-alpine";
        extraOptions = [
          "--network=twenty-network"
          "--network-alias=twenty-redis"
        ];
      };

      twenty-server-init = {
        image = "twentycrm/twenty:latest";
        volumes = ["${dataDir}/storage:/app/docker-data"];
        user = "root";
        cmd = [
          "sh"
          "-c"
          ''
            chown -R 1000:1000 /app/docker-data

            apk update
            apk add build-base g++ cairo-dev pango-dev giflib-dev python3
            yarn
            yarn command:prod workspace:sync-metadata
          ''
        ];
        dependsOn = ["twenty-db" "twenty-redis"];
        extraOptions = [
          "--network=twenty-network"
        ];
      };

      twenty-server = {
        image = "twentycrm/twenty:latest";
        ports = ["11431:3000/tcp"];
        volumes = ["${dataDir}/storage:/app/docker-data"];
        environment = {
          DISABLE_DB_MIGRATIONS = "true";
          DATABASE_URL = "postgres://postgres:postgres@twenty-db:5432/postgres";
          REDIS_HOST = "twenty-redis";
          REDIS_PORT = "6379";
        };
        dependsOn = ["twenty-server-init"];
        extraOptions = [
          "--network=twenty-network"
        ];
      };

      twenty-worker = {
        image = "twentycrm/twenty:latest";
        volumes = ["${dataDir}/storage:/app/docker-data"];
        cmd = [
          "yarn"
          "worker:prod"
        ];
        environment = {
          DISABLE_DB_MIGRATIONS = "true";
          DATABASE_URL = "postgres://postgres:postgres@twenty-db:5432/postgres";
          REDIS_HOST = "twenty-redis";
          REDIS_PORT = "6379";
        };
        dependsOn = ["twenty-server-init"];
        extraOptions = [
          "--network=twenty-network"
        ];
      };
    };

    systemd.services.docker-twenty-server-init = {
      serviceConfig = {
        Restart = lib.mkForce "on-failure";
      };
    };

    services.caddy.virtualHosts."twenty.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11431
    '';

    services.restic.paths = [dataDir];
  };
}
