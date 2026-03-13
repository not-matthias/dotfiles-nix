{
  config,
  lib,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.soulsync;

  configPath = "${cfg.dataDir}/config/config.json";
  databasePath = "${cfg.dataDir}/data/music_library.db";
in {
  options.services.soulsync = {
    enable = lib.mkEnableOption "SoulSync music discovery service";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.soulsync;
      description = "SoulSync package to run";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/soulsync";
      description = "Persistent SoulSync data directory";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "soulsync";
      description = "User account for SoulSync";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "soulsync";
      description = "Group account for SoulSync";
    };

    slskdUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:${toString (config.services.slskd.settings.web.port or 5030)}";
      description = "slskd API URL used for initial config.json generation";
    };

    caddy.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Expose SoulSync through Caddy";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mkIf (cfg.user == "soulsync") {
      soulsync = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        createHome = false;
      };
    };

    users.groups = lib.mkIf (cfg.group == "soulsync") {
      soulsync = {};
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/config 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/data 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/logs 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/downloads 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/Transfer 0750 ${cfg.user} ${cfg.group} -"
      "d ${cfg.dataDir}/Staging 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.soulsync = {
      description = "SoulSync";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      preStart = ''
                if [ ! -f "${configPath}" ]; then
                  cp "${cfg.package}/share/soulsync/config/config.example.json" "${configPath}"
                  chmod 0640 "${configPath}"

                  ${pkgs.python3}/bin/python - <<'PY'
        import json
        from pathlib import Path

        config_path = Path("${configPath}")
        data_dir = Path("${cfg.dataDir}")
        with config_path.open() as f:
            cfg = json.load(f)

        cfg.setdefault("soulseek", {})["slskd_url"] = "${cfg.slskdUrl}"
        cfg["soulseek"]["download_path"] = str(data_dir / "downloads")
        cfg["soulseek"]["transfer_path"] = str(data_dir / "Transfer")
        cfg.setdefault("logging", {})["path"] = str(data_dir / "logs" / "app.log")
        cfg.setdefault("database", {})["path"] = str(data_dir / "data" / "music_library.db")

        with config_path.open("w") as f:
            json.dump(cfg, f, indent=2)
            f.write("\n")
        PY
                fi
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        Environment = [
          "SOULSYNC_CONFIG_PATH=${configPath}"
          "DATABASE_PATH=${databasePath}"
          "HOME=${cfg.dataDir}"
          "PYTHONUNBUFFERED=1"
        ];
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };

    networking.firewall.allowedTCPPorts = [8008];

    services.caddy.virtualHosts = lib.mkIf cfg.caddy.enable {
      "soulsync.${domain}".extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:8008
      '';
    };

    services.restic.paths = [cfg.dataDir];
  };
}
