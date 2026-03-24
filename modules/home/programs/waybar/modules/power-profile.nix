{pkgs}: let
  script = pkgs.writeShellScriptBin "power_profile" ''
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")

    if [ -f /var/run/override.pickle ]; then
      # Forced mode — show the governor with a force indicator
      case "$GOVERNOR" in
        "performance") echo '{"text": "󱐌", "tooltip": "Performance (forced)", "class": "performance"}' ;;
        "powersave")   echo '{"text": "󰌪", "tooltip": "Powersave (forced)", "class": "power-saver"}' ;;
        *)             echo '{"text": "⚡", "tooltip": "Forced: '"$GOVERNOR"'", "class": "unknown"}' ;;
      esac
    else
      # Auto mode — auto-cpufreq manages it
      echo '{"text": "󰗑", "tooltip": "Auto ('"$GOVERNOR"')", "class": "auto"}'
    fi
  '';

  toggle = pkgs.writeShellScriptBin "power_profile_toggle" ''
    if [ ! -f /var/run/override.pickle ]; then
      sudo auto-cpufreq --force performance
    elif [ "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" = "performance" ]; then
      sudo auto-cpufreq --force powersave
    else
      sudo auto-cpufreq --force reset
    fi
    pkill -RTMIN+9 waybar
  '';
in {
  inherit script;

  config = {
    "custom/power_profile" = {
      return-type = "json";
      format = "{text}";
      exec = "${script}/bin/power_profile";
      interval = 30;
      on-click = "${toggle}/bin/power_profile_toggle";
      signal = 9;
    };
  };
}
