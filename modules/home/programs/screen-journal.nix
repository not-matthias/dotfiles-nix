# References:
# - https://github.com/JerryZLiu/Dayflow
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.screen-journal;

  script = pkgs.writeShellScriptBin "screen-journal" ''
    #!/bin/sh
    # Ensure we have a display to capture
    export DISPLAY=:0
    export WAYLAND_DISPLAY=wayland-1

    ${optionalString cfg.video.enable ''
      # Video recording mode
      YEAR=$(date +"%Y")
      MONTH=$(date +"%m")
      DAY=$(date +"%d")
      VIDEO_DIR="$HOME/Videos/journal/$YEAR/$MONTH"
      mkdir -p "$VIDEO_DIR"

      BASE_VIDEO_FILE="$VIDEO_DIR/$YEAR-$MONTH-$DAY"
      PID_FILE="$VIDEO_DIR/.$YEAR-$MONTH-$DAY.pid"

      # Check if recording is already running
      if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # Stop existing recording
        VIDEO_FILE="$BASE_VIDEO_FILE.mkv"
        kill "$(cat "$PID_FILE")" && rm -f "$PID_FILE"
        echo "Stopped video recording: $VIDEO_FILE"
      else
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
          nohup ${pkgs.wf-recorder}/bin/wf-recorder -o "$MONITOR" -f "$VIDEO_FILE" -r ${toString cfg.video.fps} -c hevc_vaapi -p preset=medium >/dev/null 2>&1 &
          RECORDER_PID=$!
        else
          nohup ${pkgs.wf-recorder}/bin/wf-recorder -f "$VIDEO_FILE" -r ${toString cfg.video.fps} -c hevc_vaapi -p preset=medium >/dev/null 2>&1 &
          RECORDER_PID=$!
        fi

        # Wait a moment to ensure process started
        sleep 0.5

        # Verify the process is actually running
        if kill -0 $RECORDER_PID 2>/dev/null; then
          echo $RECORDER_PID > "$PID_FILE"
          echo "Started video recording: $VIDEO_FILE (PID: $RECORDER_PID)"
        else
          echo "Error: Failed to start wf-recorder" >&2
          exit 1
        fi
      fi
    ''}

    ${optionalString cfg.image.enable ''
      # Screenshot mode
      # Create screen journal directory structure YYYY/MM/DD
      YEAR=$(date +"%Y")
      MONTH=$(date +"%m")
      DAY=$(date +"%d")
      SCREENSHOT_DIR="$HOME/Pictures/Screenshots/journal/$YEAR/$MONTH/$DAY"
      mkdir -p "$SCREENSHOT_DIR"

      # Generate filename with full date and time
      FULL_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
      TEMP_FILENAME="$SCREENSHOT_DIR/$FULL_TIMESTAMP.png"

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

      # Take screenshot using grim (Wayland only)
      if [ -n "$WAYLAND_DISPLAY" ] && command -v grim >/dev/null 2>&1; then
          if [ -n "$MONITOR" ]; then
              ${pkgs.grim}/bin/grim -o "$MONITOR" "$TEMP_FILENAME"
          else
              ${pkgs.grim}/bin/grim "$TEMP_FILENAME"
          fi
      else
          echo "Wayland screenshot tool (grim) not available" >&2
          exit 1
      fi

      # Compress and optimize the image
      OPTIMIZED_FILENAME="$SCREENSHOT_DIR/$FULL_TIMESTAMP.webp"

      # Convert to WebP with quality setting for significant size reduction
      ${pkgs.imagemagick}/bin/convert "$TEMP_FILENAME" \
          -quality ${toString cfg.image.quality} \
          -define webp:method=6 \
          -define webp:preprocessing=2 \
          "$OPTIMIZED_FILENAME"

      # Remove the original PNG
      rm "$TEMP_FILENAME"

      # Check for duplicate screenshots using perceptual hash
      if [ "${toString cfg.image.deduplication.enable}" = "true" ]; then
          CURRENT_HASH=$(${pkgs.imagemagick}/bin/identify -format "%#" "$OPTIMIZED_FILENAME")
          HASH_FILE="$SCREENSHOT_DIR/.hashes"

          # Check if this hash already exists today
          if [ -f "$HASH_FILE" ] && grep -q "^$CURRENT_HASH$" "$HASH_FILE"; then
              echo "Duplicate screenshot detected, removing: $OPTIMIZED_FILENAME"
              rm "$OPTIMIZED_FILENAME"
          else
              echo "$CURRENT_HASH" >> "$HASH_FILE"
          fi
      fi
    ''}
  '';
in {
  options.programs.screen-journal = {
    enable = mkEnableOption "screen journal for tracking activity over time";

    schedule = mkOption {
      type = types.str;
      default = "*:*:0/30";
      description = "Cron-like schedule for taking journal entries (systemd OnCalendar format). For video mode, this starts/stops daily recordings.";
      example = "*:*:0/30";
    };

    monitor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Specific monitor to capture (e.g., 'eDP-1', 'HDMI-A-1'). If null, captures all monitors.";
      example = "eDP-1";
    };

    video = {
      enable = mkEnableOption "video recording mode";

      fps = mkOption {
        type = types.int;
        default = 2;
        description = "Frames per second for video recording mode (1-30)";
        example = 5;
      };
    };

    image = {
      enable = mkEnableOption "screenshot mode";

      quality = mkOption {
        type = types.int;
        default = 75;
        description = "WebP compression quality for screenshots (0-100)";
        example = 60;
      };

      deduplication = {
        enable = mkEnableOption "duplicate screenshot detection and removal";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs;
      [
        grim # Wayland screenshot tool
        imagemagick # For WebP conversion and image processing
        wlr-randr # Monitor detection (Niri)
        jq # JSON parsing (Hyprland)
      ]
      ++ optionals cfg.video.enable [
        wf-recorder # Wayland video recording
      ];

    systemd.user.services.screen-journal = {
      Unit = {
        Description =
          if cfg.video.enable
          then "Video journal recording"
          else "Take screen journal entry";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${script}/bin/screen-journal";
        RemainAfterExit = cfg.video.enable;
      };
    };

    systemd.user.timers.screen-journal = {
      Unit = {
        Description =
          if cfg.video.enable
          then "Start/stop daily video journal recordings"
          else "Capture screen journal entry on schedule";
      };
      Timer = {
        OnCalendar =
          if cfg.video.enable
          then "daily"
          else "${cfg.schedule}";
        Persistent = true;
      };
      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}
