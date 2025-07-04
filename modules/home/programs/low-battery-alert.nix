{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.low-battery-alert;

  script = pkgs.writeShellScriptBin "low-battery-check" ''
    #!/bin/sh
    # Ensure we have a display to notify
    export DISPLAY=:0
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

    for battery in /sys/class/power_supply/BAT*; do
        if [ -d "$battery" ]; then
            capacity=$(cat "$battery/capacity")
            status=$(cat "$battery/status")

            if [ "$status" = "Discharging" ] && [ "$capacity" -le 20 ]; then
                ${pkgs.libnotify}/bin/notify-send -u critical "Low Battery" "Battery level is at $capacity%!"
            fi
        fi
    done
  '';
in {
  options.programs.low-battery-alert = {
    enable = mkEnableOption "low battery alert";
  };

  config = mkIf cfg.enable {
    systemd.user.services.low-battery-check = {
      Unit = {
        Description = "Check for low battery";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "''${script}/bin/low-battery-check";
      };
    };

    systemd.user.timers.low-battery-check = {
      Unit = {
        Description = "Run low battery check every 5 minutes";
      };
      Timer = {
        OnCalendar = "*:0/5";
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
