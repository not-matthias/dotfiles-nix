# Video journal for recording screen activity over time
# Records low-FPS video continuously with start/stop toggle capability
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

    # Video recording mode
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    VIDEO_DIR="$HOME/Videos/journal/$YEAR/$MONTH"
    mkdir -p "$VIDEO_DIR" || { echo "Error: Failed to create directory $VIDEO_DIR" >&2; exit 1; }

    BASE_VIDEO_FILE="$VIDEO_DIR/$YEAR-$MONTH-$DAY"
    PID_FILE="$VIDEO_DIR/.$YEAR-$MONTH-$DAY.pid"

    # Check if recording is already running
    if [ -f "$PID_FILE" ]; then
      OLD_PID=$(cat "$PID_FILE")
      if kill -0 "$OLD_PID" 2>/dev/null; then
        # Stop existing recording
        VIDEO_FILE="$BASE_VIDEO_FILE.mkv"
        kill "$OLD_PID" && rm -f "$PID_FILE"
        echo "Stopped video recording: $VIDEO_FILE"
      else
        # Stale PID file, clean it up
        rm -f "$PID_FILE"
      fi
    fi

    # Only start new recording if we're not in stop mode
    if [ ! -f "$PID_FILE" ]; then
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
        # Auto-detect: prefer external monitor, fallback to laptop screen
        if pgrep -x niri >/dev/null 2>&1; then
          # Niri: use wlr-randr
          EXTERNAL=$(${pkgs.wlr-randr}/bin/wlr-randr | grep -E "^(HDMI|DP|DisplayPort)" | head -1 | cut -d' ' -f1)
          if [ -n "$EXTERNAL" ]; then
            MONITOR="$EXTERNAL"
          else
            MONITOR=$(${pkgs.wlr-randr}/bin/wlr-randr | grep -E "^eDP" | head -1 | cut -d' ' -f1)
          fi
        elif [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl >/dev/null 2>&1; then
          # Hyprland: use hyprctl
          EXTERNAL=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | test("^(HDMI|DP)")) | .name' | head -1)
          if [ -n "$EXTERNAL" ]; then
            MONITOR="$EXTERNAL"
          else
            MONITOR=$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | test("^eDP")) | .name' | head -1)
          fi
        else
          # Fallback: capture all monitors
          MONITOR=""
        fi
      ''
    }

      # Start new recording (use nohup to detach properly)
      # Use MKV for crash resilience (MKV is inherently recoverable if killed)
      if [ -n "$MONITOR" ]; then
        nohup ${pkgs.wf-recorder}/bin/wf-recorder -o "$MONITOR" -f "$VIDEO_FILE" -r ${toString cfg.fps} -c hevc_vaapi -p preset=medium >/dev/null 2>&1 &
        RECORDER_PID=$!
      else
        nohup ${pkgs.wf-recorder}/bin/wf-recorder -f "$VIDEO_FILE" -r ${toString cfg.fps} -c hevc_vaapi -p preset=medium >/dev/null 2>&1 &
        RECORDER_PID=$!
      fi

      # Wait a moment to ensure process started
      sleep 0.5

      # Verify the process is actually running and write PID atomically
      if kill -0 $RECORDER_PID 2>/dev/null; then
        # Use atomic write with temp file + move
        echo $RECORDER_PID > "$PID_FILE.tmp" && mv "$PID_FILE.tmp" "$PID_FILE"
        echo "Started video recording: $VIDEO_FILE (PID: $RECORDER_PID)"
      else
        echo "Error: Failed to start wf-recorder" >&2
        exit 1
      fi
    fi # End of "start new recording" block
  '';
in {
  options.programs.video-journal = {
    enable = mkEnableOption "video journal for recording screen activity over time";

    schedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Schedule for starting/stopping daily recordings (systemd OnCalendar format)";
      example = "daily";
    };

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

    autoStart = mkEnableOption "automatically start video recording on login";
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs; [
      wf-recorder # Wayland video recording
      wlr-randr # Monitor detection (Niri)
      jq # JSON parsing (Hyprland)
    ];

    systemd.user.services.video-journal = mkMerge [
      {
        Unit = {
          Description = "Video journal recording toggle";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${script}/bin/video-journal";
          RemainAfterExit = false;
        };
      }
      (mkIf cfg.autoStart {
        Install = {
          WantedBy = ["default.target"];
        };
      })
    ];

    systemd.user.timers.video-journal = mkIf (!cfg.autoStart) {
      Unit = {
        Description = "Toggle video journal recording on schedule";
      };
      Timer = {
        OnCalendar = "${cfg.schedule}";
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
