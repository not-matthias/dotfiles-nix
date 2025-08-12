{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.logto-custom;
in {
  options.services.logto-custom = {
    enable = lib.mkEnableOption "Logto authentication service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
      description = "Port for Logto service";
    };

    adminPort = lib.mkOption {
      type = lib.types.port;
      default = 3002;
      description = "Port for Logto admin interface";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "logto.${domain}";
      description = "Domain for Logto service";
    };

    adminDomain = lib.mkOption {
      type = lib.types.str;
      default = "logto-admin.${domain}";
      description = "Domain for Logto admin interface";
    };

    dbPassword = lib.mkOption {
      type = lib.types.str;
      default = "logto_secure_password";
      description = "PostgreSQL password for Logto database";
    };
  };

  config = lib.mkIf cfg.enable {
    # PostgreSQL database configuration
    services.postgresql = {
      enable = true;
      ensureDatabases = ["logto"];
      ensureUsers = [
        {
          name = "logto";
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
            superuser = true;
            createdb = true;
            createrole = true;
          };
        }
      ];
      authentication = lib.mkAfter ''
        # Allow local connections for logto user
        local logto logto trust
        host logto logto 127.0.0.1/32 trust
        host logto logto 172.17.0.0/16 trust
      '';
    };

    # Logto OCI container
    virtualisation.oci-containers.containers = {
      "logto" = {
        image = "docker.io/svhd/logto:latest";
        environment = {
          "TRUST_PROXY_HEADER" = "1";
          "DB_URL" = "postgresql://logto:${cfg.dbPassword}@localhost:5432/logto";
          "ENDPOINT" = "https://${cfg.domain}";
          "ADMIN_ENDPOINT" = "https://${cfg.adminDomain}";
        };
        extraOptions = [
          "--pull=always"
          "--network=host"
        ];
        entrypoint = "/bin/sh";
        cmd = ["-c" "npm run cli db seed -- --swe && npm start"];
      };
    };

    # Ensure PostgreSQL is running before starting Logto
    systemd.services."docker-logto" = {
      requires = ["postgresql.service"];
      after = ["postgresql.service"];
    };

    # Caddy reverse proxy configuration
    services.caddy.virtualHosts = {
      "${cfg.domain}".extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:${toString cfg.port}
      '';
      "${cfg.adminDomain}".extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:${toString cfg.adminPort}
      '';
    };

    # Add to restic backups
    services.restic.paths = [
      "/var/lib/containers/storage/volumes/logto-data"
    ];
  };
}
