{pkgs}: let
  script = pkgs.writeShellScriptBin "temperature" ''
    # Try to get CPU temperature from different sources
    TEMP=""

    # Try thermal zone (most common)
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP=$((TEMP_RAW / 1000))
    # Try sensors command if available
    elif command -v sensors >/dev/null 2>&1; then
        TEMP=$(sensors 2>/dev/null | grep -E "Core 0|Tctl|Tdie" | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
    fi

    if [ -n "$TEMP" ] && [ "$TEMP" -gt 0 ]; then
        if [ "$TEMP" -gt 80 ]; then
            CLASS="critical"
        elif [ "$TEMP" -gt 70 ]; then
            CLASS="warning"
        else
            CLASS="normal"
        fi
        echo "{\"text\": \"''${TEMP}°C\", \"tooltip\": \"CPU Temperature: ''${TEMP}°C\", \"class\": \"$CLASS\"}"
    else
        echo '{"text": "temp", "tooltip": "Temperature unavailable", "class": "unavailable"}'
    fi
  '';
in {
  inherit script;

  # Module configuration for waybar settings
  config = {
    "custom/temperature" = {
      return-type = "json";
      format = "{text}";
      exec = "${script}/bin/temperature";
      interval = 5;
    };
  };
}
