# NOTE: Didn't use arion for this, because I ran into random issues that made no sense. It was
# the same error as mentioned in this thread: https://github.com/solidtime-io/solidtime/discussions/413
#
# To bypass email verification without setting up SMTP:
# sudo -u postgres psql -d solidtime -c "UPDATE users SET email_verified_at = NOW() WHERE email_verified_at IS NULL;"
{
  lib,
  config,
  domain,
  pkgs,
  ...
}: let
  cfg = config.services.solidtime;

  dataDir = "/var/lib/solidtime";
  network = "solidtime-network";

  laravel-env = {
    APP_NAME = "solidtime";
    VITE_APP_NAME = "solidtime";
    APP_ENV = "production";
    APP_DEBUG = "false";
    APP_URL = "solidtime.${domain}";
    APP_FORCE_HTTPS = "false";
    TRUSTED_PROXIES = "0.0.0.0/0,2000:0:0:0:0:0:0:0/3";

    # Authentication (REQUIRED)
    # This is set within `solidtime.age`
    # APP_KEY = "";
    # PASSPORT_PRIVATE_KEY = "";
    # PASSPORT_PUBLIC_KEY = "";
    # SUPER_ADMINS = "";

    # Logging
    LOG_CHANNEL = "stderr_daily";
    LOG_LEVEL = "info";

    # Database
    DB_CONNECTION = "pgsql";
    DB_HOST = "host.docker.internal";
    DB_PORT = toString config.services.postgresql.settings.port;
    DB_SSLMODE = "disable"; # IMPORTANT: We can't enable this, otherwise it won't connect
    DB_DATABASE = "solidtime";
    DB_USERNAME = "solidtime";
    DB_PASSWORD = ""; # Not needed, we allow local access

    # Mail
    MAIL_MAILER = "smtp";
    MAIL_HOST = "";
    MAIL_PORT = "";
    MAIL_ENCRYPTION = "tls";
    MAIL_FROM_ADDRESS = "no-reply@your-domain.com";
    MAIL_FROM_NAME = "solidtime";
    MAIL_USERNAME = "";
    MAIL_PASSWORD = "";

    # Queue
    QUEUE_CONNECTION = "database";

    # File storage
    FILESYSTEM_DISK = "local";
    PUBLIC_FILESYSTEM_DISK = "public";

    # Services
    GOTENBERG_URL = "http://host.docker.internal:3001";

    # Cache and Session
    CACHE_DRIVER = "file";
    SESSION_DRIVER = "cookie";
  };
in {
  options.services.solidtime = {
    enable = lib.mkEnableOption "Enable Solidtime time tracking service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8002;
      description = "Port to expose Solidtime on";
    };

    appKey = lib.mkOption {
      type = lib.types.str;
      default = "base64:K4s1pVc6LyQK4s1pVc6LyQK4s1pVc6LyQK4s1pVc6LQ=";
      description = "Laravel APP_KEY for encryption";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "0.9.0";
      description = "Docker image version tag for Solidtime";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      solidtime = {
        file = ../../../secrets/solidtime.age;
        owner = "root";
        group = "root";
        mode = "0600";
      };
    };

    services = {
      postgresql = {
        enable = true;
        enableTCPIP = true;
        settings = {
          listen_addresses = lib.mkForce "*";
        };
        ensureDatabases = ["solidtime"];
        ensureUsers = [
          {
            name = "solidtime";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              superuser = true;
            };
          }
        ];
        authentication = lib.mkAfter ''
          # Allow local connections for solidtime user
          local all all               trust
          host  all all ::1/128       trust
          host  all all 127.0.0.1/32  trust
          host  all all 172.17.0.0/16 trust
          host  all all 172.23.0.0/16 trust
          host  all all 0.0.0.0/0     md5
        '';
      };
      gotenberg = {
        enable = true;
        port = 3001;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/app 0755 1000 1000 -"
      "d ${dataDir}/logs 0755 1000 1000 -"
      "d ${dataDir}/storage 0755 1000 1000 -"
      "d ${dataDir}/storage/framework 0755 1000 1000 -"
      "d ${dataDir}/storage/framework/cache 0755 1000 1000 -"
      "d ${dataDir}/storage/framework/cache/data 0755 1000 1000 -"
      "d ${dataDir}/storage/framework/sessions 0755 1000 1000 -"
      "d ${dataDir}/storage/framework/views 0755 1000 1000 -"
    ];

    systemd.services.init-solidtime-network = {
      description = "Create the network ${network}";
      after = [
        "network.target"
        "docker.service"
      ];
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker network inspect ${network} >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create ${network}
      '';
    };

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers = {
      "solidtime-app" = {
        image = "solidtime/solidtime:${cfg.version}";
        ports = ["${toString cfg.port}:8000"];
        user = "1000:1000";
        dependsOn = [];
        volumes = [
          "${dataDir}/storage:/var/www/html/storage"
          "${dataDir}/logs:/var/www/html/storage/logs"
          "${dataDir}/app:/var/www/html/storage/app"
        ];
        environment =
          laravel-env
          // {
            CONTAINER_MODE = "http";
            AUTO_DB_MIGRATE = "true";
            APP_ENABLE_REGISTRATION = "true";
          };
        environmentFiles = [
          config.age.secrets.solidtime.path
        ];
        extraOptions = [
          "--network=${network}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };

      "solidtime-scheduler" = {
        image = "solidtime/solidtime:${cfg.version}";
        user = "1000:1000";
        ports = ["${toString (cfg.port + 1)}:8000"];
        volumes = [
          "${dataDir}/storage:/var/www/html/storage"
          "${dataDir}/logs:/var/www/html/storage/logs"
          "${dataDir}/app:/var/www/html/storage/app"
        ];
        environment =
          laravel-env
          // {
            CONTAINER_MODE = "scheduler";
          };
        environmentFiles = [
          config.age.secrets.solidtime.path
        ];
        extraOptions = [
          "--network=${network}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };

      "solidtime-queue" = {
        image = "solidtime/solidtime:${cfg.version}";
        user = "1000:1000";
        ports = ["${toString (cfg.port + 1)}:8000"];
        volumes = [
          "${dataDir}/storage:/var/www/html/storage"
          "${dataDir}/logs:/var/www/html/storage/logs"
          "${dataDir}/app:/var/www/html/storage/app"
        ];
        environment =
          laravel-env
          // {
            CONTAINER_MODE = "worker";
            WORKER_COMMAND = "php /var/www/html/artisan queue:work";
          };
        environmentFiles = [
          config.age.secrets.solidtime.path
        ];
        extraOptions = [
          "--network=${network}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };
    };

    services.caddy.virtualHosts."solidtime.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString cfg.port}
    '';

    services.restic.paths = [
      "/var/lib/solidtime/app-storage"
      "/var/lib/solidtime/logs"
    ];
  };
}
