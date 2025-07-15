{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.sccache;
in {
  options.programs.sccache = {
    enable = mkEnableOption "sccache, a shared compilation cache";

    cacheDir = mkOption {
      type = types.str;
      default = "/var/cache/sccache";
      description = "Directory to store the sccache cache";
    };

    maxCacheSize = mkOption {
      type = types.str;
      default = "10G";
      description = "Maximum size of the sccache cache";
    };

    serverMode = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to run sccache in server mode";
    };

    serverPort = mkOption {
      type = types.port;
      default = 10600;
      description = "Port for sccache server mode";
    };

    logLevel = mkOption {
      type = types.enum ["error" "warn" "info" "debug" "trace"];
      default = "info";
      description = "Log level for sccache";
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables for sccache";
    };
  };

  config = mkIf cfg.enable {
    # Install sccache system-wide
    environment.systemPackages = with pkgs; [
      sccache
    ];

    # Create cache directory
    systemd.tmpfiles.rules = [
      "d ${cfg.cacheDir} 0755 sccache sccache -"
    ];

    # Create sccache user and group
    users.users.sccache = {
      isSystemUser = true;
      group = "sccache";
      home = cfg.cacheDir;
      createHome = true;
    };

    users.groups.sccache = {};

    # System-wide environment variables
    environment.variables =
      {
        SCCACHE_DIR = cfg.cacheDir;
        SCCACHE_CACHE_SIZE = cfg.maxCacheSize;
        SCCACHE_LOG = cfg.logLevel;
        RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
        CC = "${pkgs.sccache}/bin/sccache ${pkgs.gcc}/bin/gcc";
        CXX = "${pkgs.sccache}/bin/sccache ${pkgs.gcc}/bin/g++";
      }
      // cfg.extraEnvironment;

    # Optional: sccache server service
    systemd.services.sccache-server = mkIf cfg.serverMode {
      description = "Sccache compilation cache server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "sccache";
        Group = "sccache";
        WorkingDirectory = cfg.cacheDir;
        ExecStart = "${pkgs.sccache}/bin/sccache --start-server --port ${toString cfg.serverPort}";
        ExecStop = "${pkgs.sccache}/bin/sccache --stop-server";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [cfg.cacheDir];
      };

      environment =
        {
          SCCACHE_DIR = cfg.cacheDir;
          SCCACHE_CACHE_SIZE = cfg.maxCacheSize;
          SCCACHE_LOG = cfg.logLevel;
        }
        // cfg.extraEnvironment;
    };

    # Firewall rules for server mode
    networking.firewall.allowedTCPPorts = mkIf cfg.serverMode [
      cfg.serverPort
    ];

    # Cleanup service for cache maintenance
    systemd.services.sccache-cleanup = {
      description = "Cleanup sccache cache";
      serviceConfig = {
        Type = "oneshot";
        User = "sccache";
        Group = "sccache";
        ExecStart = "${pkgs.sccache}/bin/sccache --zero-stats";
      };
    };

    systemd.timers.sccache-cleanup = {
      description = "Cleanup sccache cache regularly";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };
  };
}
