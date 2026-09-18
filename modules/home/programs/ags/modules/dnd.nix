{pkgs}:
pkgs.writeShellApplication {
  name = "ags-dnd-status";
  runtimeInputs = [pkgs.dunst pkgs.jq];
  text = ''
    state="$(${pkgs.dunst}/bin/dunstctl is-paused 2>/dev/null || true)"
    if [ "$state" = "true" ]; then
      ${pkgs.jq}/bin/jq -cn '{text: "󰂛", tooltip: "Do not disturb: ON", class: "active"}'
    else
      ${pkgs.jq}/bin/jq -cn '{text: "󰂚", tooltip: "Do not disturb: OFF", class: "inactive"}'
    fi
  '';
}
