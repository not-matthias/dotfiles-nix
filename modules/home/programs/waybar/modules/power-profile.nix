{pkgs}: let
  script = pkgs.writeShellScriptBin "power_profile" ''
    if command -v powerprofilesctl >/dev/null 2>&1; then
        PROFILE=$(powerprofilesctl get 2>/dev/null || echo "unknown")
        case "$PROFILE" in
            "power-saver") echo '{"text": "eco", "tooltip": "Power Saver Mode", "class": "power-saver"}' ;;
            "balanced") echo '{"text": "bal", "tooltip": "Balanced Mode", "class": "balanced"}' ;;
            "performance") echo '{"text": "perf", "tooltip": "Performance Mode", "class": "performance"}' ;;
            *) echo '{"text": "pwr", "tooltip": "Power Profile Unknown", "class": "unknown"}' ;;
        esac
    else
        echo '{"text": "pwr", "tooltip": "Power Profiles Not Available", "class": "unavailable"}'
    fi
  '';
in {
  inherit script;

  # Module configuration for waybar settings
  config = {
    "custom/power_profile" = {
      return-type = "json";
      format = "{text}";
      exec = "${script}/bin/power_profile";
      interval = 30;
      on-click = "powerprofilesctl set performance";
      on-click-right = "powerprofilesctl set power-saver";
      on-click-middle = "powerprofilesctl set balanced";
    };
  };
}
