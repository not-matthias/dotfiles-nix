{
  lib,
  config,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.maybe;

  # Hardcoded secrets for testing (TODO: migrate to agenix for production)
  secretsFile = pkgs.writeText "maybe-secrets" ''
    SECRET_KEY_BASE=34ce31bd003f1d9da3a36bd53aae75f239f22199ad9b8d4d113adad3bfc2dd679782e9fdbb641bf6c58e6e41e91e22996edb1ce7bf44d9ddcda0936ee85e7d31
    POSTGRES_PASSWORD=EKEMmN6T+07bX8IpsbAMcFctOTanjyz6y/iWMhxF05Q=
  '';
in {
  options.services.maybe = {
    enable = lib.mkEnableOption "Enable Maybe Finance";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3060;
      description = "Port to expose Maybe Finance on";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.arion.backend = "docker";

    virtualisation.arion.projects.maybe.settings.services = {
      maybe-app.service = {
        image = "ghcr.io/maybe-finance/maybe:latest";
        container_name = "maybe-app";
        hostname = "maybe";
        restart = "unless-stopped";
        volumes = [
          "/var/lib/maybe/app:/rails/storage:rw"
        ];
        ports = [
          "${toString cfg.port}:3000/tcp"
        ];
        environment = {
          SELF_HOSTED = "true";
          RAILS_FORCE_SSL = "false";
          RAILS_ASSUME_SSL = "false";
          GOOD_JOB_EXECUTION_MODE = "async";
          DB_HOST = "maybe-postgres";
          POSTGRES_DB = "maybe_production";
          POSTGRES_USER = "maybe_user";
        };
        depends_on = {
          maybe-postgres.condition = "service_healthy";
        };
        env_file = [
          "${secretsFile}"
        ];
      };

      maybe-postgres.service = {
        image = "postgres:16";
        container_name = "maybe-postgres";
        hostname = "maybe-postgres";
        restart = "unless-stopped";
        volumes = [
          "/var/lib/maybe/postgres:/var/lib/postgresql/data:rw"
        ];
        environment = {
          POSTGRES_USER = "maybe_user";
          POSTGRES_DB = "maybe_production";
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
      "d /var/lib/maybe 0755 root root -"
      "d /var/lib/maybe/app 0755 root root -"
      "d /var/lib/maybe/postgres 0755 root root -"
    ];

    # Configure Caddy reverse proxy
    services.caddy.virtualHosts."maybe.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString cfg.port}
    '';

    # Backup configuration
    services.restic.paths = ["/var/lib/maybe"];
  };
}
