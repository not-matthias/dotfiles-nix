{
  lib,
  config,
  domain,
  pkgs,
  ...
}: let
  cfg = config.services.twenty;

  dataDir = "/var/lib/twenty";
  network = "twenty-network";

  serverEnv = {
    NODE_PORT = "3000";
    SERVER_URL = "https://twenty.${domain}";
    REDIS_URL = "redis://host.docker.internal:6382";
    PG_DATABASE_URL = "postgres://postgres:postgres@twenty_db:5432/default";
    STORAGE_TYPE = "local";
    APP_SECRET = "your-app-secret-here";
  };
in {
  options.services.twenty = {
    enable = lib.mkEnableOption "Twenty CRM service";
    version = lib.mkOption {
      type = lib.types.str;
      default = "v1.5";
    };
  };

  config = lib.mkIf cfg.enable {
    services.redis.servers.twenty = {
      enable = true;
      port = 6382;
      bind = "0.0.0.0";
      settings.protected-mode = "no";
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/db 0755 70 70 -"
      "d ${dataDir}/storage 0755 1000 1000 -"
    ];

    systemd.services.init-twenty-network = {
      description = "Create the network ${network} for Twenty.";
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

    # Ensure containers wait for network to be created
    systemd.services.docker-twenty_db = {
      after = ["init-twenty-network.service"];
      requires = ["init-twenty-network.service"];
    };
    systemd.services.docker-twenty_server = {
      after = ["init-twenty-network.service"];
      requires = ["init-twenty-network.service"];
    };
    systemd.services.docker-twenty_worker = {
      after = ["init-twenty-network.service"];
      requires = ["init-twenty-network.service"];
    };

    virtualisation.oci-containers = {
      containers = {
        twenty_db = {
          autoStart = true;
          image = "postgres:16-alpine";
          volumes = ["${dataDir}/db:/var/lib/postgresql/data"];
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_PASSWORD = "postgres";
          };
          extraOptions = ["--network=${network}"];
        };

        twenty_server = {
          autoStart = true;
          image = "twentycrm/twenty:${cfg.version}";
          ports = [
            "3625:3000"
          ];
          volumes = [
            "${dataDir}/storage:/app/packages/twenty-server/.local-storage"
          ];
          environment = serverEnv;
          extraOptions = [
            "--network=${network}"
            "--add-host=host.docker.internal:host-gateway"
          ];
          dependsOn = [
            "twenty_db"
          ];
        };

        twenty_worker = {
          autoStart = true;
          image = "twentycrm/twenty:${cfg.version}";
          volumes = [
            "${dataDir}/storage:/app/packages/twenty-server/.local-storage"
          ];
          cmd = [
            "yarn"
            "worker:prod"
          ];
          environment =
            serverEnv
            // {
              DISABLE_DB_MIGRATIONS = "true";
            };
          extraOptions = [
            "--network=${network}"
            "--add-host=host.docker.internal:host-gateway"
          ];
          dependsOn = [
            "twenty_db"
            "twenty_server"
          ];
        };
      };
    };

    services.caddy.virtualHosts."twenty.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:3625
    '';

    services.restic.paths = [dataDir];
  };
}
