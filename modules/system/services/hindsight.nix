{
  config,
  domain,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.hindsight;
  image = "ghcr.io/vectorize-io/hindsight:1.2.0@sha256:19d0c08f3df79acac29384826419a1ca158129e81ec527cdcbd8c97ff4ef76da";
  decisionImage = "vllm/vllm-openai-cpu:v0.32.0@sha256:ffaba3989b9b96d95a576143c872a4110ce9800f5199b6a36eb27bdff1cbbe05";
  credentials = "/var/lib/hindsight/chatgpt";
  modelCache = "/var/lib/hindsight/cache";
  decisionState = "/var/lib/hindsight/decision";
  decisionCredentials = "/var/lib/hindsight/decision.env";
  claudeCredentials = "/var/lib/hindsight/claude.env";
  decisionRevision = "b9a782058dbc81ad59d9397bf2a9fed946778cb3";
  decisionSource = pkgs.fetchgit {
    url = "https://huggingface.co/hindsight-ai/hs-decide-1-flash";
    rev = decisionRevision;
    hash = "sha256-3VHKZO7/0xFGRzHgFnHSeiLYRaRb07zNr2P5lK/ZMHE=";
    fetchLFS = true;
  };
  container = "docker-hindsight";
  login = pkgs.writeShellScriptBin "hindsight-chatgpt-login" ''
    exec ${pkgs.docker}/bin/docker run --rm --network=host \
      --volume ${credentials}:${credentials}:rw \
      --env HINDSIGHT_API_LLM_CHATGPT_HOME=${credentials} \
      --entrypoint hindsight-admin \
      ${image} chatgpt login --no-browser "$@"
  '';
  claudeLogin = pkgs.writeShellScriptBin "hindsight-claude-login" ''
    set -eu
    ${pkgs.docker}/bin/docker run --rm -it \
      --entrypoint /app/api/.venv/lib/python3.11/site-packages/claude_agent_sdk/_bundled/claude \
      ${image} setup-token
    printf 'Paste the token printed above: '
    read -rs token
    echo
    [ -n "$token" ] || { echo "No token entered" >&2; exit 1; }
    printf 'HINDSIGHT_API_LLM_1_API_KEY=%s\n' "$token" \
      | sudo sh -c 'umask 077 && cat > ${claudeCredentials}'
    sudo systemctl restart ${container}.service
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
        "d ${modelCache} 0700 1000 1000 -"
        "d ${decisionState} 0700 1000 1000 -"
        "f ${claudeCredentials} 0600 root root -"
      ];
      services.hindsight-decision-credentials = {
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          if [ ! -e ${decisionCredentials} ]; then
            umask 077
            printf 'HINDSIGHT_API_DECISION_MODEL_API_KEY=%s\n' \
              "$(${pkgs.openssl}/bin/openssl rand -hex 32)" > ${decisionCredentials}
          fi
        '';
      };
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
        requires = [
          "postgresql.service"
          "hindsight-database-extensions.service"
          "hindsight-decision-credentials.service"
          "docker-hindsight-decision.service"
        ];
        after = [
          "postgresql.service"
          "hindsight-database-extensions.service"
          "hindsight-decision-credentials.service"
          "docker-hindsight-decision.service"
        ];
      };
      services.docker-hindsight-decision = {
        requires = ["hindsight-decision-credentials.service"];
        after = ["hindsight-decision-credentials.service"];
        postStart = ''
          ${pkgs.curl}/bin/curl --fail --silent --show-error \
            --retry 180 --retry-connrefused --retry-delay 2 --retry-max-time 360 \
            http://127.0.0.1:8889/health
        '';
      };
    };

    virtualisation.oci-containers.containers.hindsight-decision = {
      image = decisionImage;
      autoStart = true;
      environmentFiles = [decisionCredentials];
      environment = {
        HOME = "/tmp";
        HF_HUB_OFFLINE = "1";
        OMP_NUM_THREADS = "8";
        PYTHONPATH = "/tmp/decision-plugin";
        UV_OFFLINE = "1";
        VLLM_CPU_KVCACHE_SPACE = "2";
        VLLM_CPU_OMP_THREADS_BIND = "nobind";
        XDG_CACHE_HOME = "/cache";
      };
      entrypoint = "/bin/bash";
      cmd = [
        "-euc"
        ''
          cp -r /model/serving /tmp/serving
          chmod -R u+w /tmp/serving
          uv pip install --python /opt/venv/bin/python3 \
            --no-deps --no-build-isolation --target /tmp/decision-plugin /tmp/serving
          export PATH=/tmp/decision-plugin/bin:$PATH
          export VLLM_API_KEY="$HINDSIGHT_API_DECISION_MODEL_API_KEY"
          exec hindsight-decision-serve /model \
            --host 127.0.0.1 --port 8889 --served-model-name hs-decide-1-flash \
            --enforce-eager --max-num-seqs 2 --no-enable-prefix-caching
        ''
      ];
      volumes = [
        "${decisionSource}:/model:ro"
        "${decisionState}:/cache:rw"
      ];
      extraOptions = ["--network=host" "--shm-size=2g"];
    };

    virtualisation.oci-containers.containers.hindsight = {
      inherit image;
      autoStart = true;
      environmentFiles = [
        config.age.secrets.hindsight-server-env.path
        decisionCredentials
        claudeCredentials
      ];
      environment = {
        HINDSIGHT_API_DATABASE_URL = "postgresql://hindsight@127.0.0.1:5432/hindsight";
        HINDSIGHT_API_DECISION_MODEL_PROVIDER = "hindsight";
        HINDSIGHT_API_DECISION_MODEL_MODEL = "hs-decide-1-flash";
        HINDSIGHT_API_DECISION_MODEL_BASE_URL = "http://127.0.0.1:8889";
        HINDSIGHT_API_DECISION_MODEL_MAX_CONCURRENT = "2";
        HINDSIGHT_API_HOST = "127.0.0.1";
        HINDSIGHT_API_LLM_1_PROVIDER = "claude-code";
        HINDSIGHT_API_LLM_1_MODEL = "haiku";
        HINDSIGHT_API_LLM_1_MAX_RETRIES = "3";
        HINDSIGHT_API_LLM_CHATGPT_HOME = credentials;
        HINDSIGHT_API_LLM_MAX_RETRIES = "0";
        HINDSIGHT_API_LLM_OUTPUT_LANGUAGE = "English";
        HINDSIGHT_API_LLM_MODEL = "gpt-6-luna";
        HINDSIGHT_API_LLM_PROVIDER = "chatgpt";
        HINDSIGHT_API_LLM_STRATEGY = builtins.toJSON {mode = "failover";};
        # Mental-model refreshes fall back to the slow claude-code member
        # whenever the ChatGPT plan quota is exhausted; 600s cancelled the
        # largest models mid-refresh.
        HINDSIGHT_API_REFLECT_WALL_TIMEOUT = "1800";
        HINDSIGHT_API_RERANKER_PROVIDER = "local";
        HINDSIGHT_API_RERANKER_LOCAL_MODEL = "hindsight-ai/hs-rerank-1";
        HINDSIGHT_API_RERANKER_LOCAL_FORCE_CPU = "true";
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
      volumes = [
        "${credentials}:${credentials}:rw"
        "${modelCache}:/home/hindsight/.cache:rw"
      ];
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

    environment.systemPackages = [login claudeLogin];
    services.restic.paths = [credentials];
  };
}
