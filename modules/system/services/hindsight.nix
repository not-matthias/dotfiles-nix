{
  config,
  domain,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hindsight;
  image = "ghcr.io/vectorize-io/hindsight:1.1.0@sha256:97e5a1b0fab0ebb2c313976f6ec772b8d858b762230766670633872fc438994a";
  credentials = "/var/lib/hindsight/chatgpt";
  container = "docker-hindsight";
  login = pkgs.writeShellScriptBin "hindsight-chatgpt-login" ''
    exec ${pkgs.docker}/bin/docker run --rm --network=host \
      --volume ${credentials}:${credentials}:rw \
      --env HINDSIGHT_API_LLM_CHATGPT_HOME=${credentials} \
      --entrypoint hindsight-admin \
      ${image} chatgpt login --no-browser "$@"
  '';
in {
  options.services.hindsight.enable = lib.mkEnableOption "Hindsight memory service";

  config = lib.mkIf cfg.enable {
    age.secrets.hindsight-server-env = {
      file = ../../../secrets/hindsight-server-env.age;
      mode = "0400";
    };
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
    services.postgresql = {
      enable = true;
      extensions = ps: [ps.pgvector];
      ensureDatabases = ["hindsight"];
      ensureUsers = [
        {
          name = "hindsight";
          ensureDBOwnership = true;
          ensureClauses.login = true;
        }
      ];
      authentication = lib.mkBefore ''
        local hindsight hindsight trust
        host hindsight hindsight 127.0.0.1/32 trust
        host hindsight all 0.0.0.0/0 reject
        host hindsight all ::/0 reject
      '';
    };

    systemd = {
      tmpfiles.rules = [
        "d /var/lib/hindsight 0700 1000 1000 -"
        "d ${credentials} 0700 1000 1000 -"
      ];
      services.hindsight-database-extensions = {
        description = "Create Hindsight PostgreSQL extensions before migrations";
        # Database creation runs in postgresql-setup, after PostgreSQL is ready.
        requires = ["postgresql-setup.service"];
        after = ["postgresql-setup.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
        };
        script = ''
          ${config.services.postgresql.package}/bin/psql --dbname=hindsight --set=ON_ERROR_STOP=1 \
            --command='CREATE EXTENSION IF NOT EXISTS vector; CREATE EXTENSION IF NOT EXISTS pg_trgm;'
        '';
      };
      services."${container}" = {
        requires = ["postgresql.service" "hindsight-database-extensions.service"];
        after = ["postgresql.service" "hindsight-database-extensions.service"];
      };
    };

    virtualisation.oci-containers.containers.hindsight = {
      inherit image;
      autoStart = true;
      environmentFiles = [config.age.secrets.hindsight-server-env.path];
      environment = {
        HINDSIGHT_API_DATABASE_URL = "postgresql://hindsight@127.0.0.1:5432/hindsight";
        HINDSIGHT_API_HOST = "127.0.0.1";
        HINDSIGHT_API_LLM_CHATGPT_HOME = credentials;
        HINDSIGHT_API_LLM_OUTPUT_LANGUAGE = "English";
        HINDSIGHT_API_LLM_PROVIDER = "chatgpt";
        HINDSIGHT_API_RUN_MIGRATIONS_ON_STARTUP = "true";
        HINDSIGHT_API_TENANT_EXTENSION = "hindsight_api.extensions.builtin.tenant:ApiKeyTenantExtension";
        HINDSIGHT_API_VECTOR_EXTENSION = "pgvector";
        HINDSIGHT_API_WORKER_ID = "hindsight-pc";
        HINDSIGHT_CP_DATAPLANE_API_URL = "http://127.0.0.1:8888";
        HINDSIGHT_CP_HOSTNAME = "127.0.0.1";
        HINDSIGHT_CP_PORT = "9999";
        HINDSIGHT_ENABLE_API = "true";
        HINDSIGHT_ENABLE_CP = "true";
      };
      volumes = ["${credentials}:${credentials}:rw"];
      extraOptions = ["--network=host" "--pull=always"];
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [443];
    services.caddy.enable = true;
    services.caddy.virtualHosts = {
      "hindsight.${domain}".extraConfig = ''
        reverse_proxy http://127.0.0.1:8888
      '';
      "hindsight-ui.${domain}".extraConfig = ''
        reverse_proxy http://127.0.0.1:9999
      '';
    };

    environment.systemPackages = [login];
    services.restic.paths = [credentials];
  };
}
