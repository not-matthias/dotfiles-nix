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
}: let
  flashgenWordCfg = config.programs.waybar.flashgenWordOfHour;
in {
  options.programs.waybar.flashgenWordOfHour = {
    enable = (lib.mkEnableOption "Flashgen passive word-of-the-hour Waybar module") // {default = true;};

    dbPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documents/technical/git/flashgen/data/sinostack.db";
      description = "Mutable Flashgen SQLite database path. This remains an absolute path instead of importing the DB into the Nix store.";
    };

    hskLevel = lib.mkOption {
      type = lib.types.ints.between 1 9;
      default = 3;
      description = "HSK level to rotate through.";
    };

    hskVersion = lib.mkOption {
      type = lib.types.enum [2 3];
      default = 3;
      description = "HSK version to read from the Flashgen database.";
    };
  };

  config = {
    stylix.targets.waybar.enable = false;
    home.packages = lib.mkIf config.programs.waybar.enable [pkgs.pavucontrol];

    programs.waybar = let
      isNiri = osConfig.desktop.niri.enable or false;
      isHyprland = osConfig.desktop.hyprland.enable or false;

      # Import custom modules
      dndModule = import ./modules/dnd.nix {inherit pkgs;};
      weatherModule = import ./modules/weather.nix {inherit pkgs;};
      temperatureModule = import ./modules/temperature.nix {inherit pkgs;};
      niriWindowIndexModule = import ./modules/niri-window-index.nix {inherit pkgs;};
      aiUsageModule = import ./modules/ai-usage.nix {inherit pkgs;};
      flashgenWordModule = import ./modules/flashgen-word.nix {
        inherit pkgs;
        cfg = flashgenWordCfg;
      };

      # Merge all custom module configurations
      customModules =
        dndModule.config
        // weatherModule.config
        // temperatureModule.config
        // niriWindowIndexModule.config
        // aiUsageModule.config
        // lib.optionalAttrs flashgenWordCfg.enable flashgenWordModule.config;
      customStyles =
        lib.optionalString flashgenWordCfg.enable flashgenWordModule.style;
    in {
      settings.mainbar =
        customModules
        // {
          layer = "top";
          position = "top";
          height = 32;
          margin-bottom = -10;
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
              "group/ai-usage"
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
              "pulseaudio"
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

          "group/ai-usage" = {
            orientation = "horizontal";
            modules =
              lib.optional flashgenWordCfg.enable "custom/flashgen-word"
              ++ [
                "custom/claude-usage"
                "custom/codex-usage"
                "custom/umans-usage"
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
            format-alt = "{:%H:%M:%S}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "left";
              on-scroll = 1;
              format = {
                months = "<span color='#df8e1d'><b>{}</b></span>";
                days = "<span color='#4c4f69'>{}</span>";
                weeks = "<span color='#179299'><b>W{}</b></span>";
                weekdays = "<span color='#fe640b'><b>{}</b></span>";
                today = "<span color='#d20f39'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
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
        }; # end customModules merge

      style = (builtins.readFile ./style.css) + customStyles;
    };
  };
}
