# Screenshot journal for tracking activity over time
# Automatically captures and optimizes screenshots on a schedule
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

    # Create screen journal directory structure YYYY/MM/DD
    YEAR=$(date +"%Y")
    MONTH=$(date +"%m")
    DAY=$(date +"%d")
    SCREENSHOT_DIR="$HOME/Pictures/Screenshots/journal/$YEAR/$MONTH/$DAY"
    mkdir -p "$SCREENSHOT_DIR" || { echo "Error: Failed to create directory $SCREENSHOT_DIR" >&2; exit 1; }

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
            ${pkgs.grim}/bin/grim -o "$MONITOR" "$TEMP_FILENAME" || { echo "Error: grim screenshot failed" >&2; exit 1; }
        else
            ${pkgs.grim}/bin/grim "$TEMP_FILENAME" || { echo "Error: grim screenshot failed" >&2; exit 1; }
        fi
    else
        echo "Wayland screenshot tool (grim) not available" >&2
        exit 1
    fi

    # Compress and optimize the image
    OPTIMIZED_FILENAME="$SCREENSHOT_DIR/$FULL_TIMESTAMP.webp"

    # Convert to WebP with quality setting for significant size reduction
    if ${pkgs.imagemagick}/bin/convert "$TEMP_FILENAME" \
        -quality ${toString cfg.quality} \
        -define webp:method=6 \
        -define webp:preprocessing=2 \
        "$OPTIMIZED_FILENAME"; then
      # Remove the original PNG only if conversion succeeded
      rm "$TEMP_FILENAME"
    else
      echo "Error: WebP conversion failed, keeping original PNG" >&2
      exit 1
    fi

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
  options.programs.screenshot-journal = {
    enable = mkEnableOption "screenshot journal for tracking activity over time";

    schedule = mkOption {
      type = types.str;
      default = "*:*:0/30";
      description = "Cron-like schedule for taking journal screenshots (systemd OnCalendar format)";
      example = "*:*:0/30";
    };

    monitor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Specific monitor to capture (e.g., 'eDP-1', 'HDMI-A-1'). If null, auto-detects monitor.";
      example = "eDP-1";
    };

    quality = mkOption {
      type = types.ints.between 0 100;
      default = 75;
      description = "WebP compression quality for screenshots (0-100)";
      example = 60;
    };

    deduplication = {
      enable = mkEnableOption "duplicate screenshot detection and removal";
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs; [
      grim # Wayland screenshot tool
      imagemagick # For WebP conversion and image processing
      wlr-randr # Monitor detection (Niri)
      jq # JSON parsing (Hyprland)
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
        Description = "Capture screenshot journal entry on schedule";
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
