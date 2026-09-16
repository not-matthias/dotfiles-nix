{pkgs}:
pkgs.writeShellApplication {
  name = "eww-volume-status";
  runtimeInputs = [pkgs.gawk pkgs.jq pkgs.wireplumber];
  text = ''
    volume="$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)" || {
      ${pkgs.jq}/bin/jq -cn '{text: "vol unavailable", tooltip: "Audio sink unavailable", class: "unavailable"}'
      exit 0
    }

    if [[ "$volume" == *"[MUTED]"* ]]; then
      ${pkgs.jq}/bin/jq -cn '{text: "vol muted", tooltip: "Volume: muted", class: "muted"}'
      exit 0
    fi

    percentage="$(awk '{printf "%d", $2 * 100}' <<< "$volume")"
    ${pkgs.jq}/bin/jq -cn --arg text "vol ''${percentage}%" --argjson percentage "$percentage" \
      '{text: $text, tooltip: ("Volume: " + ($percentage | tostring) + "%"), class: "volume", percentage: $percentage}'
  '';
}
