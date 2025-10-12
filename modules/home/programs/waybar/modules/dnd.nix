{pkgs}: let
  script = pkgs.writeShellScriptBin "dnd" ''
    COUNT=$(dunstctl count waiting)
    PAUSED=$(dunstctl is-paused)

    if [ "$PAUSED" = "true" ]; then
        echo '{"text": "󰂛", "tooltip": "Notifications Paused", "class": "paused"}'
    elif [ "$COUNT" != "0" ]; then
        echo '{"text": "󰂚", "tooltip": "Notifications Active", "class": "active"}'
    else
        echo '{"text": "󰂚", "tooltip": "No new notifications", "class": "no-notifications"}'
    fi
  '';
in {
  inherit script;

  # Module configuration for waybar settings
  config = {
    "custom/dnd" = {
      return-type = "json";
      format = "{text}";
      exec = "${script}/bin/dnd";
      on-click = "dunstctl set-paused toggle";
      signal = 8;
    };
  };
}
