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
  ...
}: {
  home.packages = lib.mkIf config.programs.waybar.enable [
    pkgs.pavucontrol
  ];

  programs.waybar = let
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

    pomodoro = pkgs.writeShellScriptBin "pomodoro" ''
      STATE_FILE="/tmp/waybar-pomodoro"

      # Initialize state file if it doesn't exist
      if [ ! -f "$STATE_FILE" ]; then
          echo "idle" > "$STATE_FILE"
      fi

      STATE=$(cat "$STATE_FILE")

      case "$1" in
          "start")
              echo "work:$(date +%s):1500" > "$STATE_FILE"  # 25 min work session
              pkill -RTMIN+9 waybar
              ;;
          "break")
              echo "break:$(date +%s):300" > "$STATE_FILE"  # 5 min break
              pkill -RTMIN+9 waybar
              ;;
          "stop")
              echo "idle" > "$STATE_FILE"
              pkill -RTMIN+9 waybar
              ;;
          "toggle")
              if [ "$STATE" = "idle" ]; then
                  echo "work:$(date +%s):1500" > "$STATE_FILE"
              else
                  echo "idle" > "$STATE_FILE"
              fi
              pkill -RTMIN+9 waybar
              ;;
          *)
              # Display current state
              if [ "$STATE" = "idle" ]; then
                  echo '{"text": "󰔟", "tooltip": "Pomodoro Timer (Click to start)", "class": "idle"}'
              else
                  IFS=':' read -r mode start_time duration <<< "$STATE"
                  current_time=$(date +%s)
                  elapsed=$((current_time - start_time))
                  remaining=$((duration - elapsed))

                  if [ $remaining -le 0 ]; then
                      if [ "$mode" = "work" ]; then
                          echo "break:$(date +%s):300" > "$STATE_FILE"
                          notify-send "Pomodoro" "Work session complete! Take a 5-minute break."
                          echo '{"text": "󰔟", "tooltip": "Break time! (5:00)", "class": "break"}'
                      else
                          echo "idle" > "$STATE_FILE"
                          notify-send "Pomodoro" "Break complete! Ready for next session."
                          echo '{"text": "󰔟", "tooltip": "Pomodoro Timer (Click to start)", "class": "idle"}'
                      fi
                  else
                      minutes=$((remaining / 60))
                      seconds=$((remaining % 60))
                      time_str=$(printf "%d:%02d" $minutes $seconds)

                      if [ "$mode" = "work" ]; then
                          echo "{\"text\": \"󰔟\", \"tooltip\": \"Work session: $time_str\", \"class\": \"work\"}"
                      else
                          echo "{\"text\": \"󰔟\", \"tooltip\": \"Break time: $time_str\", \"class\": \"break\"}"
                      fi
                  fi
              fi
              ;;
      esac
    '';

    break_timer = pkgs.writeShellScriptBin "break_timer" ''
      STATE_FILE="/tmp/waybar-break-timer"

      # Initialize state file if it doesn't exist
      if [ ! -f "$STATE_FILE" ]; then
          echo "idle" > "$STATE_FILE"
      fi

      STATE=$(cat "$STATE_FILE")

      case "$1" in
          "start")
              # Prompt for break duration
              DURATION=$(echo -e "5\n10\n15\n20\n30\n45\n60" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Break duration (minutes):")
              if [ -n "$DURATION" ] && [ "$DURATION" -gt 0 ]; then
                  SECONDS=$((DURATION * 60))
                  echo "break:$(date +%s):$SECONDS" > "$STATE_FILE"
                  # Temporarily bypass DND for break start notification
                  DND_WAS_PAUSED=$(dunstctl is-paused)
                  if [ "$DND_WAS_PAUSED" = "true" ]; then
                      dunstctl set-paused false
                      notify-send "Break Timer" "Break started for $DURATION minutes"
                      sleep 0.5
                      dunstctl set-paused true
                  else
                      notify-send "Break Timer" "Break started for $DURATION minutes"
                  fi
                  pkill -RTMIN+10 waybar
              fi
              ;;
          "stop")
              echo "idle" > "$STATE_FILE"
              # Temporarily bypass DND for break cancel notification
              DND_WAS_PAUSED=$(dunstctl is-paused)
              if [ "$DND_WAS_PAUSED" = "true" ]; then
                  dunstctl set-paused false
                  notify-send "Break Timer" "Break cancelled"
                  sleep 0.5
                  dunstctl set-paused true
              else
                  notify-send "Break Timer" "Break cancelled"
              fi
              pkill -RTMIN+10 waybar
              ;;
          *)
              # Display current state
              if [ "$STATE" = "idle" ]; then
                  echo '{"text": "󰒲", "tooltip": "Break Timer (Click to start)", "class": "idle"}'
              else
                  IFS=':' read -r mode start_time duration <<< "$STATE"
                  current_time=$(date +%s)
                  elapsed=$((current_time - start_time))
                  remaining=$((duration - elapsed))

                  if [ $remaining -le 0 ]; then
                      echo "idle" > "$STATE_FILE"
                      # Play completion sound
                      ${pkgs.pulseaudio}/bin/paplay ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || \
                      ${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play -i complete 2>/dev/null || true
                      # Temporarily bypass DND for break completion notification
                      DND_WAS_PAUSED=$(dunstctl is-paused)
                      if [ "$DND_WAS_PAUSED" = "true" ]; then
                          dunstctl set-paused false
                          notify-send "Break Timer" "Break time is over! Welcome back." --urgency=critical
                          sleep 0.5  # Brief delay to ensure notification shows
                          dunstctl set-paused true
                      else
                          notify-send "Break Timer" "Break time is over! Welcome back." --urgency=critical
                      fi
                      echo '{"text": "󰒲", "tooltip": "Break Timer (Click to start)", "class": "idle"}'
                  else
                      minutes=$((remaining / 60))
                      seconds=$((remaining % 60))
                      time_str=$(printf "%d:%02d" $minutes $seconds)
                      echo "{\"text\": \"󰒲\", \"tooltip\": \"Break: $time_str remaining\", \"class\": \"active\"}"
                  fi
              fi
              ;;
      esac
    '';
  in {
    settings.mainbar = {
      layer = "top";
      position = "top";
      height = 32;
      modules-left = [
        "hyprland/workspaces"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "group/utils"
        "hyprland/language"
        "group/connectivity"
        "battery"
        "tray"
      ];

      # Group definitions
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
          "custom/pomodoro"
          "custom/break-timer"
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

      "custom/pomodoro" = {
        return-type = "json";
        format = "{text}";
        exec = "${pomodoro}/bin/pomodoro";
        on-click = "${pomodoro}/bin/pomodoro toggle";
        signal = 9;
        interval = 1;
      };
      "custom/break-timer" = {
        return-type = "json";
        format = "{text}";
        exec = "${break_timer}/bin/break_timer";
        on-click = "${break_timer}/bin/break_timer start";
        on-click-right = "${break_timer}/bin/break_timer stop";
        signal = 10;
        interval = 1;
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
