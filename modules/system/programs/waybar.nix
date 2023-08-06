# https://github.com/justinlime/dotfiles/blob/main/nix/users/brimstone/wayland/waybar.nix (https://old.reddit.com/r/unixporn/comments/13v48zn/friendship_ended_with_arch_now_nixos_is_my_best/)
{
  pkgs,
  user,
  ...
}: let
  font = "RobotoMono Nerd Font";
  # fontsize = "12";
  primary_accent = "cba6f7";
  secondary_accent = "89b4fa";
  tertiary_accent = "f5f5f5";
  background = "11111B";
  # opacity = ".85";
  # cursor = "Numix-Cursor";
in {
  environment.systemPackages = with pkgs; [
    waybar
  ];

  home-manager.users.${user} = {
    programs.waybar = {
      enable = true;
      settings.mainBar = {
        position = "top";
        layer = "top";
        height = 35;
        margin-top = 0;
        margin-bottom = 0;
        margin-left = 0;
        margin-right = 0;
        modules-left = [
          "custom/launcher"
          "custom/playerctl#backward"
          "custom/playerctl#play"
          "custom/playerctl#foward"
          "custom/playerlabel"
        ];
        modules-center = [
          "cava#left"
          "wlr/workspaces"
          "cava#right"
        ];
        modules-right = [
          "tray"
          "battery"
          "pulseaudio"
          "network"
          "clock"
        ];
        clock = {
          format = " {:%a, %d %b, %I:%M %p}";
          tooltip = "true";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = " {:%d/%m}";
        };
        "wlr/workspaces" = {
          active-only = false;
          all-outputs = false;
          disable-scroll = false;
          on-scroll-up = "hyprctl dispatch workspace e-1";
          on-scroll-down = "hyprctl dispatch workspace e+1";
          format = "{name}";
          on-click = "activate";
          format-icons = {
            urgent = "";
            active = "";
            default = "";
            sort-by-number = true;
          };
        };
        "cava#left" = {
          framerate = 60;
          autosens = 1;
          sensitivity = 100;
          bars = 18;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
          method = "pipewire";
          source = "auto";
          stereo = true;
          reverse = false;
          bar_delimiter = 0;
          monstercat = false;
          waves = false;
          input_delay = 2;
          format-icons = [
            "<span foreground='#${primary_accent}'>▁</span>"
            "<span foreground='#${primary_accent}'>▂</span>"
            "<span foreground='#${primary_accent}'>▃</span>"
            "<span foreground='#${primary_accent}'>▄</span>"
            "<span foreground='#${secondary_accent}'>▅</span>"
            "<span foreground='#${secondary_accent}'>▆</span>"
            "<span foreground='#${secondary_accent}'>▇</span>"
            "<span foreground='#${secondary_accent}'>█</span>"
          ];
        };
        "cava#right" = {
          framerate = 60;
          autosens = 1;
          sensitivity = 100;
          bars = 18;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
          method = "pipewire";
          source = "auto";
          stereo = true;
          reverse = false;
          bar_delimiter = 0;
          monstercat = false;
          waves = false;
          input_delay = 2;
          format-icons = [
            "<span foreground='#${primary_accent}'>▁</span>"
            "<span foreground='#${primary_accent}'>▂</span>"
            "<span foreground='#${primary_accent}'>▃</span>"
            "<span foreground='#${primary_accent}'>▄</span>"
            "<span foreground='#${secondary_accent}'>▅</span>"
            "<span foreground='#${secondary_accent}'>▆</span>"
            "<span foreground='#${secondary_accent}'>▇</span>"
            "<span foreground='#${secondary_accent}'>█</span>"
          ];
        };
        "custom/playerctl#backward" = {
          format = "󰙣 ";
          on-click = "playerctl previous";
          on-scroll-up = "playerctl volume .05+";
          on-scroll-down = "playerctl volume .05-";
        };
        "custom/playerctl#play" = {
          format = "{icon}";
          return-type = "json";
          exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl volume .05+";
          on-scroll-down = "playerctl volume .05-";
          format-icons = {
            Playing = "<span>󰏥 </span>";
            Paused = "<span> </span>";
            Stopped = "<span> </span>";
          };
        };
        "custom/playerctl#foward" = {
          format = "󰙡 ";
          on-click = "playerctl next";
          on-scroll-up = "playerctl volume .05+";
          on-scroll-down = "playerctl volume .05-";
        };
        "custom/playerlabel" = {
          format = "<span>󰎈 {} 󰎈</span>";
          return-type = "json";
          max-length = 40;
          exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
          on-click = "";
        };
        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-charging = "  {capacity}%";
          format-plugged = " {capacity}% ";
          format-alt = "{icon} {time}";
          format-icons = ["" "" "" "" ""];
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
          icon-size = 20;
          spacing = 8;
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            default = ["󰕿" "󰖀" "󰕾"];
          };
          # on-scroll-up= "bash ~/.scripts/volume up";
          # on-scroll-down= "bash ~/.scripts/volume down";
          scroll-step = 5;
          on-click = "pavucontrol";
        };
        "custom/randwall" = {
          format = "󰏘";
          # on-click= "bash $HOME/.config/hypr/randwall.sh";
          # on-click-right= "bash $HOME/.config/hypr/wall.sh";
        };
        "custom/launcher" = {
          format = "";
          # on-click= "bash $HOME/.config/rofi/launcher.sh";
          # on-click-right= "bash $HOME/.config/rofi/run.sh";
          tooltip = "false";
        };
      };
      style = ''
        * {
            border: none;
            border-radius: 0px;
            font-family: ${font};
            font-size: 14px;
            min-height: 0;
        }

        window#waybar {
            background: rgba(16, 18, 19, 0.8);
        }

        #cava.left, #cava.right {
            background: #${background};
            margin: 5px;
            padding: 8px 16px;
            color: #${primary_accent};
        }
        #cava.left {
            border-radius: 24px 10px 24px 10px;
        }
        #cava.right {
            border-radius: 10px 24px 10px 24px;
        }
        #workspaces {
            background: #${background};
            margin: 5px 5px;
            padding: 8px 5px;
            border-radius: 16px;
            color: #${primary_accent}
        }
        #workspaces button {
            padding: 0px 5px;
            margin: 0px 3px;
            border-radius: 16px;
            color: transparent;
            background-color: #2f354a;
            transition: all 0.3s ease-in-out;
        }

        #workspaces button.active {
            background-color: #${secondary_accent};
            color: #${background};
            border-radius: 16px;
            min-width: 50px;
            background-size: 400% 400%;
            transition: all 0.3s ease-in-out;
        }

        #workspaces button:hover {
            background-color: #${tertiary_accent};
            color: #${background};
            border-radius: 16px;
            min-width: 50px;
            background-size: 400% 400%;
        }

        #tray, #pulseaudio, #network, #battery,
        #custom-playerctl.backward, #custom-playerctl.play, #custom-playerctl.foward{
            background: #${background};
            font-weight: bold;
            margin: 5px 0px;
        }
        #tray, #pulseaudio, #network, #battery{
            color: #${tertiary_accent};
            border-radius: 10px 24px 10px 24px;
            padding: 0 20px;
            margin-left: 7px;
        }
        #clock {
            color: #${tertiary_accent};
            background-color: #${background};
            border-radius: 0px 0px 0px 40px;
            padding: 10px 10px 15px 25px;
            margin-left: 7px;
            font-weight: bold;
            font-size: 16px;
        }
        #custom-launcher {
            color: #${secondary_accent};
            background-color: #${background};
            border-radius: 0px 0px 40px 0px;
            margin: 0px;
            padding: 0px 35px 0px 15px;
            font-size: 28px;
        }

        #custom-playerctl.backward, #custom-playerctl.play, #custom-playerctl.foward {
            background: #${background};
            font-size: 22px;
        }
        #custom-playerctl.backward:hover, #custom-playerctl.play:hover, #custom-playerctl.foward:hover{
            color: #${tertiary_accent};
        }
        #custom-playerctl.backward {
            color: #${primary_accent};
            border-radius: 24px 0px 0px 10px;
            padding-left: 16px;
            margin-left: 7px;
        }
        #custom-playerctl.play {
            color: #${secondary_accent};
            padding: 0 5px;
        }
        #custom-playerctl.foward {
            color: #${primary_accent};
            border-radius: 0px 10px 24px 0px;
            padding-right: 12px;
            margin-right: 7px
        }
        #custom-playerlabel {
            background: #${background};
            color: #${tertiary_accent};
            padding: 0 20px;
            border-radius: 24px 10px 24px 10px;
            margin: 5px 0;
            font-weight: bold;
        }
        #window{
            background: #${background};
            padding-left: 15px;
            padding-right: 15px;
            border-radius: 16px;
            margin-top: 5px;
            margin-bottom: 5px;
            font-weight: normal;
            font-style: normal;
        }
      '';
    };
  };
}
