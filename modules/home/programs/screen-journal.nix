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

    MODE="${cfg.mode}"

    if [ "$MODE" = "video" ]; then
      # Video recording mode
      YEAR=$(date +"%Y")
      MONTH=$(date +"%m")
      DAY=$(date +"%d")
      VIDEO_DIR="$HOME/Videos/journal/$YEAR/$MONTH"
      mkdir -p "$VIDEO_DIR"

      VIDEO_FILE="$VIDEO_DIR/$YEAR-$MONTH-$DAY.mp4"
      PID_FILE="$VIDEO_DIR/.$YEAR-$MONTH-$DAY.pid"

      # Check if recording is already running
      if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        # Stop existing recording
        kill "$(cat "$PID_FILE")" && rm -f "$PID_FILE"
        echo "Stopped video recording: $VIDEO_FILE"
      else
        # Start new recording
        if [ "${toString cfg.singleMonitor}" = "true" ]; then
          # Single monitor detection for video
          OUTPUT=""
          if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl >/dev/null 2>&1; then
            CURSOR_INFO=$(${pkgs.hyprland}/bin/hyprctl cursorpos)
            MOUSE_X=$(echo "$CURSOR_INFO" | cut -d',' -f1)
            MOUSE_Y=$(echo "$CURSOR_INFO" | cut -d',' -f2)
            OUTPUT=$(${pkgs.hyprland}/bin/hyprctl monitors -j | \
                    ${pkgs.jq}/bin/jq -r ".[] | select(.x <= $MOUSE_X and .y <= $MOUSE_Y and (.x + .width) > $MOUSE_X and (.y + .height) > $MOUSE_Y) | .name")
          elif pgrep -x niri >/dev/null 2>&1; then
            MOUSE_POS=$(${pkgs.wlrctl}/bin/wlrctl pointer | head -1)
            MOUSE_X=$(echo "$MOUSE_POS" | cut -d',' -f1)
            MOUSE_Y=$(echo "$MOUSE_POS" | cut -d',' -f2)
            for output_line in $(${pkgs.wlr-randr}/bin/wlr-randr | grep -E "^[A-Z]"); do
              OUTPUT_NAME=$(echo "$output_line" | cut -d' ' -f1)
              GEOMETRY=$(${pkgs.wlr-randr}/bin/wlr-randr | grep -A5 "^$OUTPUT_NAME" | grep "Position" | cut -d' ' -f2)
              if [ -n "$GEOMETRY" ]; then
                X_POS=$(echo "$GEOMETRY" | cut -d',' -f1)
                Y_POS=$(echo "$GEOMETRY" | cut -d',' -f2)
                SIZE=$(${pkgs.wlr-randr}/bin/wlr-randr | grep -A5 "^$OUTPUT_NAME" | grep "current" | sed 's/.*current //' | cut -d' ' -f1)
                WIDTH=$(echo "$SIZE" | cut -d'x' -f1)
                HEIGHT=$(echo "$SIZE" | cut -d'x' -f2)
                if [ "$MOUSE_X" -ge "$X_POS" ] && [ "$MOUSE_X" -lt "$((X_POS + WIDTH))" ] && \
                   [ "$MOUSE_Y" -ge "$Y_POS" ] && [ "$MOUSE_Y" -lt "$((Y_POS + HEIGHT))" ]; then
                  OUTPUT="$OUTPUT_NAME"
                  break
                fi
              fi
            done
          fi

          if [ -n "$OUTPUT" ]; then
            ${pkgs.wf-recorder}/bin/wf-recorder -o "$OUTPUT" -f "$VIDEO_FILE" -r ${toString cfg.fps} -c h264_vaapi -p preset=medium &
          else
            ${pkgs.wf-recorder}/bin/wf-recorder -f "$VIDEO_FILE" -r ${toString cfg.fps} -c h264_vaapi -p preset=medium &
          fi
        else
          ${pkgs.wf-recorder}/bin/wf-recorder -f "$VIDEO_FILE" -r ${toString cfg.fps} -c h264_vaapi -p preset=medium &
        fi

        echo $! > "$PID_FILE"
        echo "Started video recording: $VIDEO_FILE (PID: $!)"
      fi
      exit 0
    fi

    # Screenshot mode (existing functionality)
    # Create screen journal directory structure YYYY/MM/DD
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    SCREENSHOT_DIR="$HOME/Pictures/Screenshots/journal/$YEAR/$MONTH/$DAY"
    mkdir -p "$SCREENSHOT_DIR"

    # Generate filename with full date and time
    FULL_TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    TEMP_FILENAME="$SCREENSHOT_DIR/$FULL_TIMESTAMP.png"

    # Take screenshot using grim (Wayland only)
    if [ -n "$WAYLAND_DISPLAY" ] && command -v grim >/dev/null 2>&1; then
        if [ "${toString cfg.singleMonitor}" = "true" ]; then
            # Check compositor type for different mouse position methods
            if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl >/dev/null 2>&1; then
                # Hyprland: use hyprctl for cursor position
                CURSOR_INFO=$(${pkgs.hyprland}/bin/hyprctl cursorpos)
                MOUSE_X=$(echo "$CURSOR_INFO" | cut -d',' -f1)
                MOUSE_Y=$(echo "$CURSOR_INFO" | cut -d',' -f2)

                # Get monitor info from hyprctl
                OUTPUT=$(${pkgs.hyprland}/bin/hyprctl monitors -j | \
                        ${pkgs.jq}/bin/jq -r ".[] | select(.x <= $MOUSE_X and .y <= $MOUSE_Y and (.x + .width) > $MOUSE_X and (.y + .height) > $MOUSE_Y) | .name")
            elif pgrep -x niri >/dev/null 2>&1; then
                # Niri: use wlrctl for cursor position
                MOUSE_POS=$(${pkgs.wlrctl}/bin/wlrctl pointer | head -1)
                MOUSE_X=$(echo "$MOUSE_POS" | cut -d',' -f1)
                MOUSE_Y=$(echo "$MOUSE_POS" | cut -d',' -f2)

                # Use wlr-randr for Niri monitor info
                OUTPUT=""
                for output_line in $(${pkgs.wlr-randr}/bin/wlr-randr | grep -E "^[A-Z]"); do
                    OUTPUT_NAME=$(echo "$output_line" | cut -d' ' -f1)
                    GEOMETRY=$(${pkgs.wlr-randr}/bin/wlr-randr | grep -A5 "^$OUTPUT_NAME" | grep "Position" | cut -d' ' -f2)
                    if [ -n "$GEOMETRY" ]; then
                        X_POS=$(echo "$GEOMETRY" | cut -d',' -f1)
                        Y_POS=$(echo "$GEOMETRY" | cut -d',' -f2)
                        SIZE=$(${pkgs.wlr-randr}/bin/wlr-randr | grep -A5 "^$OUTPUT_NAME" | grep "current" | sed 's/.*current //' | cut -d' ' -f1)
                        WIDTH=$(echo "$SIZE" | cut -d'x' -f1)
                        HEIGHT=$(echo "$SIZE" | cut -d'x' -f2)

                        if [ "$MOUSE_X" -ge "$X_POS" ] && [ "$MOUSE_X" -lt "$((X_POS + WIDTH))" ] && \
                           [ "$MOUSE_Y" -ge "$Y_POS" ] && [ "$MOUSE_Y" -lt "$((Y_POS + HEIGHT))" ]; then
                            OUTPUT="$OUTPUT_NAME"
                            break
                        fi
                    fi
                done
            else
                # Fallback for other wlroots compositors
                OUTPUT=""
            fi

            if [ -n "$OUTPUT" ]; then
                ${pkgs.grim}/bin/grim -o "$OUTPUT" "$TEMP_FILENAME"
            else
                # Fallback to full screenshot
                ${pkgs.grim}/bin/grim "$TEMP_FILENAME"
            fi
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
        -quality ${toString cfg.quality} \
        -define webp:method=6 \
        -define webp:preprocessing=2 \
        "$OPTIMIZED_FILENAME"

    # Remove the original PNG
    rm "$TEMP_FILENAME"

    # Check for duplicate screenshots using perceptual hash
    if [ "${toString cfg.deduplication.enable}" = "true" ]; then
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
  '';
in {
  options.programs.screen-journal = {
    enable = mkEnableOption "screen journal for tracking activity over time";

    mode = mkOption {
      type = types.enum ["screenshot" "video"];
      default = "screenshot";
      description = "Capture mode: individual screenshots or continuous video recording";
    };

    schedule = mkOption {
      type = types.str;
      default = "*:*:0/30";
      description = "Cron-like schedule for taking journal entries (systemd OnCalendar format). For video mode, this starts/stops daily recordings.";
      example = "*:*:0/30";
    };

    quality = mkOption {
      type = types.int;
      default = 75;
      description = "WebP compression quality for screenshots (0-100) or video bitrate for recordings";
      example = 60;
    };

    fps = mkOption {
      type = types.int;
      default = 2;
      description = "Frames per second for video recording mode (1-30)";
      example = 5;
    };

    deduplication = {
      enable = mkEnableOption "duplicate screenshot detection and removal";
    };

    singleMonitor = mkEnableOption "capture only the monitor where the mouse cursor is located";
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs;
      [
        grim # Wayland screenshot tool
        imagemagick # For WebP conversion and image processing
      ]
      ++ optionals (cfg.mode == "video") [
        wf-recorder # Wayland video recording
      ]
      ++ optionals cfg.singleMonitor [
        # Additional tools for single monitor detection
        jq # JSON parsing for Hyprland
      ]
      ++ optionals (cfg.singleMonitor && config.wayland.windowManager.hyprland.enable) [
        hyprland # Hyprctl for cursor position
      ]
      ++ optionals (cfg.singleMonitor) [
        wlrctl # Wayland mouse position (Niri)
        wlr-randr # Wayland display info (Niri)
      ];

    systemd.user.services.screen-journal = {
      Unit = {
        Description =
          if cfg.mode == "video"
          then "Video journal recording"
          else "Take screen journal entry";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${script}/bin/screen-journal";
      };
    };

    systemd.user.timers.screen-journal = {
      Unit = {
        Description =
          if cfg.mode == "video"
          then "Start/stop daily video journal recordings"
          else "Capture screen journal entry on schedule";
      };
      Timer = {
        OnCalendar =
          if cfg.mode == "video"
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
