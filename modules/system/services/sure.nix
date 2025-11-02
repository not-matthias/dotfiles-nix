{
  lib,
  config,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.sure;

  # Hardcoded secrets for testing (TODO: migrate to agenix for production)
  secretsFile = pkgs.writeText "sure-secrets" ''
    SECRET_KEY_BASE=a7523c3d0ae56415046ad8abae168d71074a79534a7062258f8d1d51ac2f76d3c3bc86d86b6b0b307df30d9a6a90a2066a3fa9e67c5e6f374dbd7dd4e0778e13
    POSTGRES_PASSWORD=sure_password
  '';
in {
  options.services.sure = {
    enable = lib.mkEnableOption "Enable Sure Finance";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port to expose Sure Finance on";
    };
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers.sure = {
      enable = true;
      port = 6381;
      bind = "0.0.0.0";
      settings.protected-mode = "no";
    };

    virtualisation.arion.backend = "docker";

    virtualisation.arion.projects.sure.settings.services = {
      web.service = {
        image = "ghcr.io/we-promise/sure:latest";
        restart = "unless-stopped";
        volumes = [
          "/var/lib/sure/app:/rails/storage:rw"
        ];
        ports = [
          "${toString cfg.port}:3000/tcp"
        ];
        environment = {
          SELF_HOSTED = "true";
          RAILS_FORCE_SSL = "false";
          RAILS_ASSUME_SSL = "false";
          DB_HOST = "db";
          DB_PORT = "5432";
          POSTGRES_DB = "sure_production";
          POSTGRES_USER = "sure_user";
          REDIS_URL = "redis://host.docker.internal:6381";
        };
        extra_hosts = [
          "host.docker.internal:host-gateway"
        ];
        depends_on = {
          db.condition = "service_healthy";
        };
        env_file = [
          "${secretsFile}"
        ];
      };

      worker.service = {
        image = "ghcr.io/we-promise/sure:latest";
        command = "bundle exec sidekiq";
        restart = "unless-stopped";
        volumes = [
          "/var/lib/sure/app:/rails/storage:rw"
        ];
        environment = {
          SELF_HOSTED = "true";
          RAILS_FORCE_SSL = "false";
          RAILS_ASSUME_SSL = "false";
          DB_HOST = "db";
          DB_PORT = "5432";
          POSTGRES_DB = "sure_production";
          POSTGRES_USER = "sure_user";
          REDIS_URL = "redis://host.docker.internal:6381";
        };
        extra_hosts = [
          "host.docker.internal:host-gateway"
        ];
        depends_on = {
          db.condition = "service_healthy";
        };
        env_file = [
          "${secretsFile}"
        ];
      };

      db.service = {
        image = "postgres:16";
        restart = "unless-stopped";
        volumes = [
          "/var/lib/sure/postgres:/var/lib/postgresql/data:rw"
        ];
        environment = {
          POSTGRES_USER = "sure_user";
          POSTGRES_DB = "sure_production";
        };
        healthcheck = {
          test = ["CMD-SHELL" "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"];
          interval = "5s";
          timeout = "5s";
          retries = 5;
          start_period = "1m";
        };
        env_file = [
          "${secretsFile}"
        ];
      };
    };

    # Ensure directories exist with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/sure 0755 root root -"
      "d /var/lib/sure/app 0755 root root -"
      "d /var/lib/sure/postgres 0755 root root -"
    ];

    # Configure Caddy reverse proxy
    services.caddy.virtualHosts."sure.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString cfg.port}
    '';

    # Backup configuration
    services.restic.paths = [
      "/var/lib/sure/app"
      "/var/lib/sure/postgres"
    ];
  };
}
