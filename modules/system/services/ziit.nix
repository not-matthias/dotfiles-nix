{
  lib,
  config,
  domain,
  pkgs,
  ...
}: let
  cfg = config.services.ziit;

  dataDir = "/var/lib/ziit";
  network = "ziit-network";
in {
  options.services.ziit = {
    enable = lib.mkEnableOption "Enable Ziit time tracking service";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8003;
      description = "Port to expose Ziit on";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "v1.0.2";
      description = "Docker image version tag for Ziit";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      ziit = {
        file = ../../../secrets/ziit.age;
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
        ensureDatabases = ["ziit"];
        ensureUsers = [
          {
            name = "ziit";
            ensureDBOwnership = true;
            ensureClauses = {
              login = true;
              superuser = true;
            };
          }
        ];
        authentication = lib.mkAfter ''
          # Allow local connections for ziit user
          local all all               trust
          host  all all ::1/128       trust
          host  all all 127.0.0.1/32  trust
          host  all all 172.17.0.0/16 trust
          host  all all 172.23.0.0/16 trust
          host  all all 0.0.0.0/0     trust
        '';
        extensions = ps: [
          ps.timescaledb
        ];
      };
    };

    systemd.tmpfiles.rules = [
      "d ${dataDir} 0755 root root -"
      "d ${dataDir}/uploads 0755 1000 1000 -"
      "d ${dataDir}/data 0755 1000 1000 -"
      "d ${dataDir}/cache 0755 1000 1000 -"
    ];

    systemd.services.init-ziit-network = {
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
      "ziit-app" = {
        image = "ghcr.io/0pandadev/ziit:${cfg.version}";
        ports = ["${toString cfg.port}:3000"];
        user = "1000:1000";
        dependsOn = [];
        volumes = [
          "${dataDir}/uploads:/app/uploads"
          "${dataDir}/data:/ziit/node_modules/.prisma"
          "${dataDir}/cache:/ziit/.cache"
        ];
        environment = {
          NUXT_DATABASE_URL = "postgresql://ziit@host.docker.internal:${toString config.services.postgresql.settings.port}/ziit";
          NUXT_BASE_URL = "https://ziit.${domain}";
          NUXT_DISABLE_REGISTRATION = "false";
          NUXT_GITHUB_CLIENT_ID = "";
          NUXT_GITHUB_CLIENT_SECRET = "";
          NUXT_EPILOGUE_APP_ID = "";
          NUXT_EPILOGUE_APP_SECRET = "";
          NODE_ENV = "production";
        };
        environmentFiles = [
          config.age.secrets.ziit.path
        ];
        extraOptions = [
          "--network=${network}"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };
    };

    services.caddy.virtualHosts."ziit.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString cfg.port}
    '';

    services.restic.paths = [
      "/var/lib/ziit/uploads"
    ];
  };
}
