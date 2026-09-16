{pkgs}:
pkgs.writeShellApplication {
  name = "eww-battery-status";
  runtimeInputs = [pkgs.coreutils pkgs.jq];
  text = ''
    for battery in /sys/class/power_supply/BAT*; do
      [ -r "$battery/capacity" ] || continue
      capacity="$(${pkgs.coreutils}/bin/cat "$battery/capacity")"
      status="$(${pkgs.coreutils}/bin/cat "$battery/status" 2>/dev/null || printf 'Unknown')"
      [[ "$capacity" =~ ^[0-9]+$ ]] || continue

      class="good"
      if [ "$capacity" -lt 15 ]; then
        class="critical"
      elif [ "$capacity" -lt 30 ]; then
        class="warning"
      fi
      ${pkgs.jq}/bin/jq -cn --arg text "bat ''${capacity}%" --arg tooltip "Battery: ''${capacity}% (''${status})" --arg class "$class" --argjson percentage "$capacity" \
        '{text: $text, tooltip: $tooltip, class: $class, percentage: $percentage}'
      exit 0
    done

    ${pkgs.jq}/bin/jq -cn '{text: "", tooltip: "No battery", class: "unavailable"}'
  '';
}
