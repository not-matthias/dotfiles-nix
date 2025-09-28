{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.screenshot-journal;

  script = pkgs.writeShellScriptBin "screenshot-journal" ''
    #!/bin/sh
    # Ensure we have a display to capture
    export DISPLAY=:0
    export WAYLAND_DISPLAY=wayland-1

    # Create screenshot journal directory structure YYYY/MM/DD
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    SCREENSHOT_DIR="$HOME/Pictures/Screenshots/journal/$YEAR/$MONTH/$DAY"
    mkdir -p "$SCREENSHOT_DIR"

    # Generate filename with full date and time
    FULL_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    FILENAME="$SCREENSHOT_DIR/$FULL_TIMESTAMP.png"

    # Take screenshot using grim (Wayland) or scrot (X11)
    # This captures all monitors as a single image
    if [ -n "$WAYLAND_DISPLAY" ] && command -v grim >/dev/null 2>&1; then
        ${pkgs.grim}/bin/grim "$FILENAME"
    elif command -v scrot >/dev/null 2>&1; then
        ${pkgs.scrot}/bin/scrot "$FILENAME"
    else
        echo "No screenshot tool available" >&2
        exit 1
    fi

  '';
in {
  options.programs.screenshot-journal = {
    enable = mkEnableOption "screenshot journal for tracking activity over time";

    schedule = mkOption {
      type = types.str;
      default = "*:*:0/30";
      description = "Cron-like schedule for taking journal entries (systemd OnCalendar format)";
      example = "*:*:0/30";
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs; [
      grim # Wayland screenshot tool
      scrot # X11 screenshot tool
    ];

    systemd.user.services.screenshot-journal = {
      Unit = {
        Description = "Take screenshot journal entry";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${script}/bin/screenshot-journal";
      };
    };

    systemd.user.timers.screenshot-journal = {
      Unit = {
        Description = "Capture screenshot journal entry on schedule: ${cfg.schedule}";
      };
      Timer = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
