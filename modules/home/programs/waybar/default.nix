# https://github.com/justinlime/dotfiles/blob/main/nix/users/brimstone/wayland/waybar.nix (https://old.reddit.com/r/unixporn/comments/13v48zn/friendship_ended_with_arch_now_nixos_is_my_best/)
# https://github.com/smravec/nixos-config/blob/main/home-manager/config/waybar.nix (https://old.reddit.com/r/unixporn/comments/124yjwy/minimalistic_sway_waybar_nixos_full_silent_boot/)
# https://github.com/linuxmobile/hyprland-dots/blob/Sakura/.config/waybar/config.jsonc
# https://github.com/adomixaszvers/dotfiles-nix/blob/519ce8dcc1d272a7ec719ddf8fe21a230c012e47/profiles/wm/hyprland/default.nix
# https://github.com/smravec/nixos-config/blob/main/home-manager/config/waybar.nix
# https://github.com/cjbassi/config/blob/master/.config/waybar/config
{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: {
  home.packages = lib.mkIf config.programs.waybar.enable [
    pkgs.pavucontrol
  ];

  programs.waybar = let
    isNiri = osConfig.desktop.niri.enable or false;
    isHyprland = osConfig.desktop.hyprland.enable or false;

    dnd = pkgs.writeShellScriptBin "dnd" ''
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

    weather = pkgs.writeShellScriptBin "weather" ''
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

    power_profile = pkgs.writeShellScriptBin "power_profile" ''
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

    temperature = pkgs.writeShellScriptBin "temperature" ''
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

    niri_window_index = pkgs.writeShellScriptBin "niri_window_index" ''
      update_display() {
          # Query niri for focused workspace
          WORKSPACE_OUTPUT=$(niri msg --json workspaces 2>/dev/null)
          FOCUSED_WS_ID=$(echo "$WORKSPACE_OUTPUT" | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused == true) | .id')

          if [ -z "$FOCUSED_WS_ID" ]; then
              echo '{"text": "", "tooltip": "No focused workspace", "class": "empty"}'
              return
          fi

          # Query niri for windows information
          WINDOWS_OUTPUT=$(niri msg --json windows 2>/dev/null)

          if [ -z "$WINDOWS_OUTPUT" ] || [ "$WINDOWS_OUTPUT" = "null" ]; then
              echo '{"text": "", "tooltip": "No windows", "class": "empty"}'
              return
          fi

          # Parse JSON to find focused window and count windows on focused workspace
          # Sort by horizontal position (pos_in_scrolling_layout[0])
          RESULT=$(echo "$WINDOWS_OUTPUT" | ${pkgs.jq}/bin/jq -r --arg ws_id "$FOCUSED_WS_ID" '
            . as $root |
            ($root | map(select(.workspace_id == ($ws_id | tonumber)))) as $ws_windows |
            ($ws_windows | sort_by(.layout.pos_in_scrolling_layout[0])) as $sorted_windows |
            ($sorted_windows | map(select(.is_focused == true)) | .[0]) as $focused |
            if ($sorted_windows | length) > 0 then
              if $focused then
                ($sorted_windows | map(.id) | index($focused.id)) as $idx |
                {
                  index: $idx,
                  total: ($sorted_windows | length)
                }
              else
                {
                  index: -1,
                  total: ($sorted_windows | length)
                }
              end
            else
              null
            end |
            if . then
              "\(.index)|\(.total)"
            else
              ""
            end
          ')

          if [ -n "$RESULT" ] && [ "$RESULT" != "null" ] && [ "$RESULT" != "" ]; then
              IFS='|' read -r INDEX TOTAL <<< "$RESULT"

              # Build dot visualization with spacing
              DOTS=""
              for ((i=0; i<TOTAL; i++)); do
                  if [ $i -gt 0 ]; then
                      DOTS="$DOTS "
                  fi
                  if [ "$INDEX" != "-1" ] && [ $i -eq $INDEX ]; then
                      DOTS="$DOTS󰪥"
                  else
                      DOTS="$DOTS󰄰"
                  fi
              done

              if [ "$INDEX" != "-1" ]; then
                  echo "{\"text\": \"$DOTS\", \"tooltip\": \"Window $INDEX/$TOTAL\", \"class\": \"active\"}"
              else
                  echo "{\"text\": \"$DOTS\", \"tooltip\": \"$TOTAL windows\", \"class\": \"inactive\"}"
              fi
          else
              echo '{"text": "", "tooltip": "No windows", "class": "empty"}'
          fi
      }

      # Initial display
      update_display

      # Listen to niri event stream for changes
      niri msg event-stream 2>/dev/null | while read -r line; do
          case "$line" in
              "Window opened or changed:"*|"Window closed:"*|"Window focus changed:"*|"Workspace focused:"*|*"active window changed to"*)
                  update_display
                  ;;
          esac
      done
    '';
  in {
    settings.mainbar = {
      layer = "top";
      position = "top";
      height = 32;
      modules-left =
        if isNiri
        then ["niri/workspaces" "group/niri-info"]
        else if isHyprland
        then ["hyprland/workspaces"]
        else [];
      modules-center = [
        "clock"
      ];
      modules-right =
        [
          "group/utils"
        ]
        ++ (
          if isNiri
          then ["niri/language"]
          else if isHyprland
          then ["hyprland/language"]
          else []
        )
        ++ [
          "battery"
          "tray"
        ];

      # Group definitions
      "group/niri-info" = {
        orientation = "horizontal";
        modules = [
          "custom/niri-window-index"
        ];
      };

      "group/system" = {
        orientation = "horizontal";
        modules = [
          "custom/temperature"
          "cpu"
          "memory"
        ];
      };

      "group/utils" = {
        orientation = "horizontal";
        modules = [
          "idle_inhibitor"
          "custom/dnd"
        ];
      };

      "group/connectivity" = {
        orientation = "horizontal";
        modules = [
          "bluetooth"
          "pulseaudio"
        ];
      };
      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";
          deactivated = "󰾪";
        };
        tooltip-format-activated = "Idle Inhibit: ON";
        tooltip-format-deactivated = "Idle Inhibit: OFF";
      };
      "custom/dnd" = {
        return-type = "json";
        format = "{text}";
        exec = "${dnd}/bin/dnd";
        on-click = "dunstctl set-paused toggle";
        signal = 8;
      };
      "custom/weather" = {
        return-type = "json";
        format = "{text}";
        exec = "${weather}/bin/weather";
        interval = 600; # Update every 10 minutes
      };
      "custom/power_profile" = {
        return-type = "json";
        format = "{text}";
        exec = "${power_profile}/bin/power_profile";
        interval = 30;
        on-click = "powerprofilesctl set performance";
        on-click-right = "powerprofilesctl set power-saver";
        on-click-middle = "powerprofilesctl set balanced";
      };
      "custom/temperature" = {
        return-type = "json";
        format = "{text}";
        exec = "${temperature}/bin/temperature";
        interval = 5;
      };
      "custom/niri-window-index" = {
        return-type = "json";
        format = "{text}";
        exec = "${niri_window_index}/bin/niri_window_index";
      };
      "hyprland/language" = {
        format-en = "en";
        format-de = "de";
      };
      "hyprland/workspaces" = {
        all-outputs = true;
        # on-click = "activate";
        # on-scroll-up = "hyprctl dispatch workspace e-1";
        # on-scroll-down = "hyprctl dispatch workspace e+1";
        # on-click = "activate";
      };
      "niri/language" = {
        format-en = "en";
        format-de = "de";
      };
      "niri/workspaces" = {
        all-outputs = false;
        # format = "{index}";
      };

      battery = {
        format = "bat {capacity}%";
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
      };
      clock = {
        format = "{:%Y-%m-%d %H:%M}";
      };
      memory = {
        format = "ram {}%";
        format-alt = "ram {used}/{total} GiB";
        interval = 5;
      };
      cpu = {
        format = "cpu {usage}%";
        format-alt = "cpu {avg_frequency} GHz";
        interval = 5;
      };
      network = {
        format-wifi = "wifi {signalStrength}%";
        format-ethernet = "eth 100%";
        tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "wifi 0%";
      };
      tray = {
        icon-size = 16;
        spacing = 8;
      };
      bluetooth = {
        format = "{icon}";
        format-on = "󰂯";
        format-off = "󰂲";
        format-disabled = "󰂲";
        format-connected = "󰂱";
        on-click = "blueman-manager";
      };
      pulseaudio = {
        format = "vol {volume}%";
        format-muted = "vol muted";
        # on-scroll-up= "bash ~/.scripts/volume up";
        # on-scroll-down= "bash ~/.scripts/volume down";
        scroll-step = 1;
        on-click = "pavucontrol";
      };
    };

    style = builtins.readFile ./style.css;
  };
}
