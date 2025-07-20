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
        image = "postgres:16";
        volumes = ["${dataDir}/db:/var/lib/postgresql/data"];
        environment = {
          POSTGRES_USER = "postgres";
          POSTGRES_PASSWORD = "postgres";
          POSTGRES_DB = "default";
        };
        extraOptions = [
          "--network=twenty-network"
          "--network-alias=db"
          "--health-cmd=pg_isready -U postgres -h localhost -d default"
          "--health-interval=5s"
          "--health-timeout=5s"
          "--health-retries=10"
        ];
      };

      twenty-redis = {
        image = "redis";
        cmd = ["--maxmemory-policy" "noeviction"];
        extraOptions = [
          "--network=twenty-network"
          "--network-alias=redis"
        ];
      };

      twenty-server = {
        image = "twentycrm/twenty:latest";
        ports = ["11431:3000/tcp"];
        volumes = ["${dataDir}/storage:/app/packages/twenty-server/.local-storage"];
        environment = {
          NODE_PORT = "3000";
          PG_DATABASE_URL = "postgres://postgres:postgres@db:5432/default";
          SERVER_URL = "https://twenty.${domain}";
          REDIS_URL = "redis://redis:6379";
          DISABLE_DB_MIGRATIONS = "false";
          DISABLE_CRON_JOBS_REGISTRATION = "false";
          STORAGE_TYPE = "local";
          APP_SECRET = "replace_me_with_a_random_string";
        };
        dependsOn = ["twenty-db"];
        extraOptions = [
          "--network=twenty-network"
          "--health-cmd=curl --fail http://localhost:3000/healthz"
          "--health-interval=5s"
          "--health-timeout=5s"
          "--health-retries=20"
        ];
      };

      twenty-worker = {
        image = "twentycrm/twenty:latest";
        volumes = ["${dataDir}/storage:/app/packages/twenty-server/.local-storage"];
        cmd = ["yarn" "worker:prod"];
        environment = {
          PG_DATABASE_URL = "postgres://postgres:postgres@db:5432/default";
          SERVER_URL = "https://twenty.${domain}";
          REDIS_URL = "redis://redis:6379";
          DISABLE_DB_MIGRATIONS = "true";
          DISABLE_CRON_JOBS_REGISTRATION = "true";
          STORAGE_TYPE = "local";
          APP_SECRET = "replace_me_with_a_random_string";
        };
        dependsOn = ["twenty-db" "twenty-server"];
        extraOptions = [
          "--network=twenty-network"
        ];
      };
    };

    services.caddy.virtualHosts."twenty.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11431
    '';

    services.restic.paths = [dataDir];
  };
}
