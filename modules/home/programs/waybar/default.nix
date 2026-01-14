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

    # Import custom modules
    dndModule = import ./modules/dnd.nix {inherit pkgs;};
    weatherModule = import ./modules/weather.nix {inherit pkgs;};
    powerProfileModule = import ./modules/power-profile.nix {inherit pkgs;};
    temperatureModule = import ./modules/temperature.nix {inherit pkgs;};
    niriWindowIndexModule = import ./modules/niri-window-index.nix {inherit pkgs;};

    # Merge all custom module configurations
    customModules =
      dndModule.config
      // weatherModule.config
      // powerProfileModule.config
      // temperatureModule.config
      // niriWindowIndexModule.config;
  in {
    settings.mainbar =
      customModules
      // {
        output = "DP-2";
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

    style = builtins.readFile ./style.css;
  };
}
