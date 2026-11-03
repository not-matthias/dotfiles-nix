{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.services.hokum;
  seedConfig = pkgs.writeText "hokum-config.kdl" ''
    theme "capsule"
    behaviour {
        sound #false
        check-for-updates #false
    }
    modules {
        sound #false
        bluetooth #false
        osd #false
        brightness #false
        bluetooth-notifications #false
    }
  '';
  configFile = "${config.xdg.configHome}/hokum/config.kdl";
in {
  options.services.hokum = {
    enable = mkEnableOption "Hokum notification daemon";
    package = mkOption {
      type = types.package;
      default = pkgs.hokum;
      defaultText = lib.literalExpression "pkgs.hokum";
      description = "The Hokum package to use for the daemon and command-line client.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    # Seed only once: Hokum's CLI and settings UI persist Do Not Disturb here.
    home.activation.hokumConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      config_file=${lib.escapeShellArg configFile}
      if [ ! -e "$config_file" ]; then
        $DRY_RUN_CMD install -Dm 0644 ${seedConfig} "$config_file"
      fi
    '';

    # Route D-Bus activation through the same session-bound systemd unit.
    xdg.dataFile."dbus-1/services/app.hokum.Notifications.service".text = ''
      [D-BUS Service]
      Name=org.freedesktop.Notifications
      Exec=${cfg.package}/bin/hokum service
      SystemdService=hokum.service
    '';

    systemd.user.services.hokum = {
      Unit = {
        Description = "Hokum notification daemon";
        Documentation = "https://hokum.app";
        After = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
        Conflicts = ["mako.service" "swaync.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${cfg.package}/bin/hokum service";
        Restart = "on-failure";
        RestartPreventExitStatus = 78;
        RestartSec = 2;
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
