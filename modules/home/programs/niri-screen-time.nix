{
  config,
  lib,
  pkgs,
  flakes,
  ...
}: let
  cfg = config.programs.niri-screen-time;
in {
  options.programs.niri-screen-time = {
    enable = lib.mkEnableOption "niri-screen-time";

    package = lib.mkOption {
      type = lib.types.package;
      default = flakes.niri-screen-time.packages.${pkgs.system}.default;
      description = "The niri-screen-time package to use";
    };

    enableDaemon = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable the niri-screen-time daemon";
    };

    subprograms = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          app_ids = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of application IDs to track";
          };

          title_list = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of window titles to track";
          };

          alias = lib.mkOption {
            type = lib.types.str;
            description = "Custom display name for this subprogram";
          };
        };
      });
      default = [];
      description = "Subprogram configurations for tracking specific applications";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."niri-screen-time/subprograms.yaml" = lib.mkIf (cfg.subprograms != []) {
      text = builtins.toJSON cfg.subprograms;
    };

    systemd.user.services.niri-screen-time = lib.mkIf cfg.enableDaemon {
      Unit = {
        Description = "Niri Screen Time Tracker";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/niri-screen-time -daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
