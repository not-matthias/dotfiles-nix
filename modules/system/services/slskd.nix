{
  lib,
  config,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.slskd;
in {
  options.services.slskd = {
    enable = lib.mkEnableOption "slskd Soulseek daemon";

    port = lib.mkOption {
      type = lib.types.port;
      default = 5030;
      description = "Port for the web interface";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/slskd";
      description = "Directory to store slskd data";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "slskd";
      description = "User to run slskd as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "slskd";
      description = "Group to run slskd as";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = {};

    systemd.services.slskd = {
      description = "slskd Soulseek daemon";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${pkgs.slskd}/bin/slskd --no-logo --no-version";
        Restart = "on-failure";
        RestartSec = 5;

        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [cfg.dataDir];
      };

      preStart = ''
                # Ensure data directory exists and has correct permissions
                mkdir -p ${cfg.dataDir}
                chown ${cfg.user}:${cfg.group} ${cfg.dataDir}

                # Create basic config if it doesn't exist
                if [ ! -f ${cfg.dataDir}/slskd.yml ]; then
                  cat > ${cfg.dataDir}/slskd.yml << EOF
        web:
          port: ${toString cfg.port}
          https:
            disabled: true
        soulseek:
          username: ""
          password: ""
        shares:
          directories: []
        downloads:
          dir: ${cfg.dataDir}/downloads
        EOF
                  chown ${cfg.user}:${cfg.group} ${cfg.dataDir}/slskd.yml
                fi
      '';
    };

    # Optional: Add reverse proxy configuration if caddy is enabled
    services.caddy.virtualHosts."slskd.${domain}" = lib.mkIf config.services.caddy.enable {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
