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
      if dunstctl is-paused | grep -q "true"; then
          echo '{"text": "󰂛", "tooltip": "Notifications Paused", "class": "paused"}'
      else
          echo '{"text": "󰂚", "tooltip": "Notifications Active"}'
      fi
    '';
  in {
    settings.mainbar = {
      layer = "top";
      position = "top";
      height = 20;
      modules-left = [
        "hyprland/workspaces"
      ];
      modules-right = [
        "custom/dnd"
        "hyprland/language"
        "bluetooth"
        "battery"
        "pulseaudio"
        "clock"
        "tray"
      ];
      "custom/dnd" = {
        return-type = "json";
        format = "{text}";
        exec = "${dnd}/bin/dnd";
        on-click = "dunstctl set-paused toggle";
        signal = 8;
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
        format = "{capacity}% {icon}";
        format-icons = ["" "" "" "" ""];
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
        format = "󰍛 {}%";
        format-alt = "󰍛 {used}/{total} GiB";
        interval = 5;
      };
      cpu = {
        format = "󰻠 {usage}%";
        format-alt = "󰻠 {avg_frequency} GHz";
        interval = 5;
      };
      network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = "󰈀 100% ";
        tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "󰖪 0% ";
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
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = {
          default = ["󰕿" "󰖀" "󰕾"];
        };
        # on-scroll-up= "bash ~/.scripts/volume up";
        # on-scroll-down= "bash ~/.scripts/volume down";
        scroll-step = 1;
        on-click = "pavucontrol";
      };
    };

    style = builtins.readFile ./style.css;
  };
}
