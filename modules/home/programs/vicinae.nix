{
  flakes,
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    flakes.vicinae.homeManagerModules.default
  ];

  options.programs.vicinae.enable = lib.mkEnableOption "vicinae launcher";

  config = lib.mkIf config.programs.vicinae.enable {
    # Add vicinae cachix for binary cache
    nix.settings = {
      substituters = [
        "https://vicinae.cachix.org"
      ];
      trusted-public-keys = [
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
    home.packages = [
      pkgs.libqalculate
    ];

    # Create config directory and files for vicinae
    xdg.configFile."vicinae/config.json" = {
      text = builtins.toJSON {
        appearance = {
          theme = "light";
          showIcons = true;
          maxResults = 8;
        };

        keybindings = {
          show = "Super+Space";
          hide = "Escape";
          selectNext = "Down";
          selectPrevious = "Up";
          accept = "Return";
          acceptInNewTab = "Cmd+Return";
        };

        modules = {
          applications = {
            enabled = true;
            priority = 100;
          };

          files = {
            enabled = true;
            priority = 80;
            searchPaths = [
              config.home.homeDirectory
              "${config.home.homeDirectory}/Documents"
              "${config.home.homeDirectory}/Downloads"
            ];
            maxDepth = 3;
          };

          calculator = {
            enabled = true;
            priority = 90;
          };

          clipboard = {
            enabled = true;
            priority = 70;
            maxItems = 100;
          };

          web = {
            enabled = true;
            priority = 60;
            searchEngines = [
              {
                name = "Brave Search";
                url = "https://search.brave.com/search?q={query}";
                default = true;
              }
              {
                name = "Nixpkgs Search";
                url = "https://search.nixos.org/packages?query={query}";
                keyword = "nix";
              }
            ];
          };
        };

        extensions = [
          {
            name = "power-management";
            commands = [
              {
                title = "Lock Screen";
                command = "playerctl --all-players pause & swaylock -f -c 000000";
                icon = "system-lock-screen";
              }
              {
                title = "Logout";
                command = "hyprctl dispatch exit";
                icon = "system-log-out";
              }
              {
                title = "Reboot";
                command = "systemctl reboot";
                icon = "system-reboot";
              }
              {
                title = "Shutdown";
                command = "systemctl poweroff";
                icon = "system-shutdown";
              }
            ];
          }
          {
            name = "development";
            commands = [
              {
                title = "Open Zed";
                command = "zed";
                icon = "code";
              }
            ];
          }
        ];
      };
    };
  };
}
