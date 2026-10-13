{
  config,
  lib,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.audiomuse-ai;
  stateDir = "/var/lib/audiomuse-ai";
  environmentFile = "${stateDir}/database.env";
  image = "ghcr.io/neptunehub/audiomuse-ai:3.6.3";
  settingsFile = (pkgs.formats.json {}).generate "audiomuse-ai-settings.json" cfg.settings;
  navidromeConfig = (pkgs.formats.json {}).generate "navidrome.json" config.services.navidrome.settings;
  databaseEnvironment = {
    TZ = config.time.timeZone;
    POSTGRES_USER = "audiomuse";
    POSTGRES_DB = "audiomusedb";
    POSTGRES_HOST = "postgres";
    POSTGRES_PORT = "5432";
  };
  appService = serviceType: {
    inherit image;
    restart = "unless-stopped";
    environment =
      databaseEnvironment
      // cfg.settings
      // {
        SERVICE_TYPE = serviceType;
        TEMP_DIR = "/app/temp_audio";
      };
    env_file = [environmentFile config.age.secrets.audiomuse-ai-env.path];
    depends_on.bootstrap.condition = "service_completed_successfully";
    extra_hosts = ["host.docker.internal:host-gateway"];
    volumes = [
      "${stateDir}/${serviceType}/temp:/app/temp_audio"
      "${stateDir}/${serviceType}/plugins:/app/plugin/installed"
    ];
  };
  plugin = pkgs.fetchurl {
    url = "https://github.com/NeptuneHub/AudioMuse-AI-NV-plugin/releases/download/v10/audiomuseai.ndp";
    hash = "sha256:c138e9af16f097d8cd07ac957fb8a49d91a7da066e5b4a1457cadbd479aa10a7";
  };
in {
  options.services.audiomuse-ai = {
    enable = lib.mkEnableOption "AudioMuse-AI sonic music analysis";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8005;
      description = "Loopback port for the AudioMuse-AI web interface";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "AudioMuse environment settings reapplied to its database at each stack start. Keep secrets in audiomuse-ai-env.age.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.audiomuse-ai.settings = lib.mapAttrs (_: lib.mkDefault) {
      MEDIASERVER_TYPE = "navidrome";
      NAVIDROME_URL = "http://host.docker.internal:${toString config.services.navidrome.settings.Port}";
      NAVIDROME_USER = "not_matthias";
      MUSIC_LIBRARIES = "";
      AUTH_ENABLED = "True";
      AUDIOMUSE_USER = "not_matthias";
      CLAP_ENABLED = "True";
      LYRICS_ENABLED = "True";
      LYRICS_API_ENABLE = "True";
      LYRICS_ASR_ENABLE = "True";
      NEURAL_FINGERPRINT_ENABLED = "False";
      AI_MODEL_PROVIDER = "NONE";
    };
    age.secrets.audiomuse-ai-env.file = ../../../secrets/audiomuse-ai-env.age;

    virtualisation.arion.backend = "docker";
    virtualisation.arion.projects.audiomuse-ai.settings.services = {
      bootstrap.service = {
        inherit image;
        restart = "no";
        environment = databaseEnvironment // cfg.settings;
        env_file = [environmentFile config.age.secrets.audiomuse-ai-env.path];
        depends_on.postgres.condition = "service_healthy";
        entrypoint = "python3 /bootstrap.py /settings.json";
        volumes = [
          "${./audiomuse-ai-bootstrap.py}:/bootstrap.py:ro"
          "${settingsFile}:/settings.json:ro"
        ];
      };
      flask.service =
        appService "flask"
        // {
          ports = ["127.0.0.1:${toString cfg.port}:8000"];
        };
      worker.service = appService "worker";
      postgres.service = {
        image = "postgres:15-alpine";
        restart = "unless-stopped";
        environment = databaseEnvironment;
        env_file = [environmentFile];
        volumes = ["${stateDir}/postgres:/var/lib/postgresql/data"];
        healthcheck = {
          test = ["CMD-SHELL" "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"];
          interval = "5s";
          timeout = "5s";
          retries = 5;
          start_period = "1m";
        };
      };
    };

    systemd.services.audiomuse-ai-init = {
      requiredBy = ["arion-audiomuse-ai.service"];
      before = ["arion-audiomuse-ai.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "audiomuse-ai";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        if [ ! -e ${environmentFile} ]; then
          password=$(${pkgs.openssl}/bin/openssl rand -hex 32)
          printf 'POSTGRES_PASSWORD=%s\n' "$password" > ${environmentFile}
        fi
        mkdir -p ${stateDir}/{postgres,flask/{temp,plugins},worker/{temp,plugins}}
      '';
    };

    services.navidrome.settings.Agents = "audiomuseai,lastfm,deezer";
    services.navidrome.settings.Plugins.Enabled = true;
    services.navidrome.plugins = [
      (pkgs.runCommand "audiomuseai-10" {
          pname = "audiomuseai";
          passthru.isNavidromePlugin = true;
        } ''
          mkdir -p $out/share
          cp ${plugin} $out/share/audiomuseai.ndp
        '')
    ];

    systemd.services.navidrome = lib.mkIf config.services.navidrome.enable {
      serviceConfig.LoadCredential = [
        "audiomuse-ai-env:${config.age.secrets.audiomuse-ai-env.path}"
      ];
      preStart = ''
        set -euo pipefail
        navidrome() {
          ${lib.getExe config.services.navidrome.finalPackage} \
            --configfile ${navidromeConfig} --nobanner "$@"
        }
        # Navidrome 0.64.2 stores --users values as IDs, not usernames.
        userIds=$(
          navidrome user list --format json --loglevel error |
            ${lib.getExe pkgs.jq} -ce \
              --arg username ${lib.escapeShellArg cfg.settings.NAVIDROME_USER} '
                [.[] | select(.username == $username) | .id]
                | if length == 1 then .
                  else error("Configured AudioMuse Navidrome user not found")
                  end
              '
        )
        navidrome plugin rescan
        ${lib.getExe pkgs.jq} -Rn \
          --arg apiUrl ${lib.escapeShellArg "http://127.0.0.1:${toString cfg.port}"} '
            [inputs | select(startswith("API_TOKEN="))
              | ltrimstr("API_TOKEN=") | rtrimstr("\r")] as $tokens
            | if ($tokens | length) != 1 or $tokens[0] == "" then
                error("Expected one non-empty API_TOKEN in AudioMuse credential")
              else
                {apiUrl: $apiUrl, apiToken: $tokens[0], server: "Navidrome"}
              end
          ' < "$CREDENTIALS_DIRECTORY/audiomuse-ai-env" |
          navidrome plugin edit audiomuseai --config-file - \
            --users "$userIds" --all-libraries --no-write-access
        navidrome plugin enable audiomuseai
      '';
    };

    services.caddy.virtualHosts."audiomuse.${domain}".extraConfig = ''
      encode zstd gzip
      @trusted remote_ip private_ranges 100.64.0.0/10
      handle @trusted {
        reverse_proxy http://127.0.0.1:${toString cfg.port}
      }
      handle {
        respond "Forbidden" 403
      }
    '';
  };
}
