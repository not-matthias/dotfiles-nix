# Video journal for recording screen activity over time
# Records low-FPS video continuously, auto-starts on login with auto-restart on crashes
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.video-journal;

  script = pkgs.writeShellScriptBin "video-journal" ''
    #!/bin/sh
    # Ensure we have a display to capture
    export DISPLAY=:0
    export WAYLAND_DISPLAY=wayland-1

    # Video recording - create directory structure
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    VIDEO_DIR="$HOME/Videos/journal/$YEAR/$MONTH"
    mkdir -p "$VIDEO_DIR" || { echo "Error: Failed to create directory $VIDEO_DIR" >&2; exit 1; }

    BASE_VIDEO_FILE="$VIDEO_DIR/$YEAR-$MONTH-$DAY"

    # Find next available filename to avoid overwriting
    COUNTER=0
    if [ -f "$BASE_VIDEO_FILE.mkv" ]; then
      COUNTER=1
      while [ -f "$BASE_VIDEO_FILE-$COUNTER.mkv" ]; do
        COUNTER=$((COUNTER + 1))
      done
      VIDEO_FILE="$BASE_VIDEO_FILE-$COUNTER.mkv"
    else
      VIDEO_FILE="$BASE_VIDEO_FILE.mkv"
    fi

    # Detect monitor
    ${
      if cfg.monitor != null
      then ''
        MONITOR="${cfg.monitor}"
      ''
      else ''
        # Auto-detect: prefer external monitor (main), fallback to laptop screen (eDP)
        if pgrep -x niri >/dev/null 2>&1; then
          # Niri: use wlr-randr to detect monitors
          # Check for external monitors first (HDMI, DisplayPort, DP)
          EXTERNAL=$(${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | grep -E "^(HDMI|DP|DisplayPort)" | grep -v "Disabled" | head -1 | awk '{print $1}')
          if [ -n "$EXTERNAL" ]; then
            MONITOR="$EXTERNAL"
            echo "Using external monitor: $MONITOR"
          else
            # No external monitor, use laptop screen
            MONITOR=$(${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | grep -E "^eDP" | grep -v "Disabled" | head -1 | awk '{print $1}')
            if [ -n "$MONITOR" ]; then
              echo "Using laptop screen: $MONITOR"
            else
              echo "Error: No active monitors detected" >&2
              exit 1
            fi
          fi
        elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl >/dev/null 2>&1; then
          # Hyprland: use hyprctl to detect monitors
          # Check for external monitors first
          EXTERNAL=$(${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.name | test("^(HDMI|DP)")) | .name' | head -1)
          if [ -n "$EXTERNAL" ]; then
            MONITOR="$EXTERNAL"
            echo "Using external monitor: $MONITOR"
          else
            # No external monitor, use laptop screen
            MONITOR=$(${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.name | test("^eDP")) | .name' | head -1)
            if [ -n "$MONITOR" ]; then
              echo "Using laptop screen: $MONITOR"
            else
              echo "Error: No active monitors detected" >&2
              exit 1
            fi
          fi
        else
          # Fallback: try wlr-randr for other Wayland compositors
          EXTERNAL=$(${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | grep -E "^(HDMI|DP|DisplayPort)" | grep -v "Disabled" | head -1 | awk '{print $1}')
          if [ -n "$EXTERNAL" ]; then
            MONITOR="$EXTERNAL"
            echo "Using external monitor: $MONITOR"
          else
            MONITOR=$(${pkgs.wlr-randr}/bin/wlr-randr 2>/dev/null | grep -E "^eDP" | grep -v "Disabled" | head -1 | awk '{print $1}')
            if [ -n "$MONITOR" ]; then
              echo "Using laptop screen: $MONITOR"
            else
              echo "Error: No active monitors detected" >&2
              exit 1
            fi
          fi
        fi
      ''
    }

    echo "Starting video recording: $VIDEO_FILE"

    # Start recording in foreground (systemd will supervise)
    # Use MKV for crash resilience (MKV is inherently recoverable if killed)
    if [ -n "$MONITOR" ]; then
      exec ${pkgs.wf-recorder}/bin/wf-recorder -o "$MONITOR" -f "$VIDEO_FILE" -r ${toString cfg.fps} -c hevc_vaapi -p preset=medium
    else
      exec ${pkgs.wf-recorder}/bin/wf-recorder -f "$VIDEO_FILE" -r ${toString cfg.fps} -c hevc_vaapi -p preset=medium
    fi
  '';
in {
  options.programs.video-journal = {
    enable = mkEnableOption "video journal for recording screen activity over time";

    monitor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Specific monitor to capture (e.g., 'eDP-1', 'HDMI-A-1'). If null, auto-detects monitor.";
      example = "eDP-1";
    };

    fps = mkOption {
      type = types.ints.between 1 30;
      default = 2;
      description = "Frames per second for video recording (1-30). Lower FPS saves disk space.";
      example = 5;
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs; [
      wf-recorder # Wayland video recording
      wlr-randr # Monitor detection (Niri)
      jq # JSON parsing (Hyprland)
    ];

    systemd.user.services.video-journal = {
      Unit = {
        Description = "Video journal continuous recording";
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${script}/bin/video-journal";
        Restart = "always";
        RestartSec = "10s";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
