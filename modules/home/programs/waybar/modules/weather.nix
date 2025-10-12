{pkgs}: let
  script = pkgs.writeShellScriptBin "weather" ''
    # Get weather data from wttr.in
    WEATHER=$(curl -s "https://wttr.in/?format=%t&m" 2>/dev/null | tr -d '+')
    if [ -z "$WEATHER" ]; then
        echo '{"text": "weather", "tooltip": "Weather unavailable", "class": "disconnected"}'
    else
        ICON="🌤"
        case $WEATHER in
            *"-"*) ICON="🥶" ;;
            *"0"*|*"1"*|*"2"*|*"3"*|*"4"*|*"5"*) ICON="❄️" ;;
            *"25"*|*"26"*|*"27"*|*"28"*|*"29"*|*"30"*) ICON="🌤" ;;
            *) ICON="☀️" ;;
        esac
        echo "{\"text\": \"$WEATHER\", \"tooltip\": \"Weather: $WEATHER\", \"class\": \"weather\"}"
    fi
  '';
in {
  inherit script;

  # Module configuration for waybar settings
  config = {
    "custom/weather" = {
      return-type = "json";
      format = "{text}";
      exec = "${script}/bin/weather";
      interval = 600; # Update every 10 minutes
    };
  };
}
