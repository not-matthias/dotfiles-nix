# TODO: Configure screen sharing
#  wl-present mirror eDP-1
{
  user,
  lib,
  flakes,
  config,
  pkgs,
  ...
}: let
  pointer = config.stylix.cursor;
  cfg = config.desktop.niri;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      imports = [
        flakes.niri.homeModules.niri
        flakes.system76-scheduler-niri.homeModules.default
        ./keybinds.nix
        ./autostart.nix
        ./env.nix
        ./input.nix
      ];

      programs = {
        swaylock.enable = true;
        waybar.enable = true;
        vicinae.enable = true;
      };

      services.system76-scheduler-niri = {
        enable = true;
      };
      services = {
        swayidle.enable = true;
        swww.enable = true;
        dunst.enable = true;
        vicinae = {
          enable = true;
          autoStart = true;
        };
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        xdgOpenUsePortal = true;
      };

      programs.niri = {
        enable = true;
        settings = {
          xwayland-satellite.enable = true;
          prefer-no-csd = true;
          hotkey-overlay.skip-at-startup = true;

          cursor = {
            size = pointer.size;
            theme = "${pointer.name}";
          };

          # Window appearance
          layout = {
            background-color = "transparent";
            gaps = 16;
            preset-column-widths = [
              {proportion = 1. / 3.;}
              {proportion = 1. / 2.;}
              {proportion = 2. / 3.;}
            ];
            default-column-width.proportion = 1. / 2.;

            focus-ring = {
              enable = true;
              width = 2;
              active.color = "#ef5350";
              inactive.color = "#595959";
            };

            border = {
              enable = false;
              width = 2;
              active.color = "#ef5350";
              inactive.color = "#595959";
            };
            # animations = {
            #   enable = false;
            # };
          };

          # Named workspaces to prevent auto-deletion when empty
          workspaces = {
            "1" = {
              name = "web";
              open-on-output = "DP-1";
            };
            "2" = {
              name = "code";
              open-on-output = "DP-1";
            };
            "3" = {
              name = "notes";
              open-on-output = "DP-1";
            };
            "4" = {
              name = "chat";
              open-on-output = "DP-1";
            };
            "5" = {
              name = "music";
              open-on-output = "DP-1";
            };
            "99" = {
              name = "scratchpad";
              open-on-output = "DP-1";
            };
          };

          # Enable shadows and rounded corners for windows
          window-rules = [
            # Default rule for all windows
            {
              matches = [{}];
              shadow.enable = true;
              geometry-corner-radius = {
                bottom-left = 5.0;
                bottom-right = 5.0;
                top-left = 5.0;
                top-right = 5.0;
              };
              clip-to-geometry = true;
            }
            # Browsers on workspace "web"
            {
              open-on-workspace = "web";
              open-maximized = true;
              matches = [
                {app-id = "^firefox$";}
                {app-id = "floorp";}
                {app-id = "^zen-browser$";}
                {app-id = "^brave$";}
                {app-id = "^chromium$";}
                {app-id = "^librewolf$";}
              ];
            }
            # Code editors on workspace "code"
            {
              open-on-workspace = "code";
              open-maximized = true;
              matches = [
                {app-id = "^code$";}
                {app-id = "^VSCodium$";}
                {app-id = "^zed$";}
                {app-id = "^neovide$";}
              ];
            }
            # Note apps on workspace "notes"
            {
              open-on-workspace = "notes";
              open-maximized = true;
              matches = [
                {app-id = "^obsidian$";}
                {app-id = "^logseq$";}
                {app-id = "^notion$";}
              ];
            }
            # Chat apps on workspace "chat"
            {
              open-on-workspace = "chat";
              matches = [
                {app-id = "^discord$";}
                {app-id = "^Discord$";}
                {app-id = "^slack$";}
                {app-id = "^element$";}
                {app-id = "^telegram$";}
                {app-id = "^BeeperTexts$";}
              ];
            }
            # Music apps on workspace "music"
            {
              open-on-workspace = "music";
              open-maximized = true;
              matches = [
                {app-id = "^spotify$";}
                {app-id = "^Spotify$";}
                {app-id = "^feishin$";}
              ];
            }
            # VLC - prevent oversized windows
            {
              matches = [
                {app-id = "^vlc$";}
                {app-id = "^org\\.videolan\\.VLC$";}
              ];
              open-maximized = false;
            }
            # Picture-in-picture windows with size constraint
            {
              open-floating = true;
              max-width = 600;
              max-height = 400;
              matches = [
                {
                  app-id = "^firefox$";
                  title = "^Picture-in-Picture$";
                }
                {
                  app-id = "^brave-browser$";
                  title = "^Picture-in-Picture$";
                }
                {
                  app-id = "^Vivaldi-stable$";
                  title = "^Picture-in-Picture$";
                }
                {
                  app-id = "^zen-(browser|beta)$";
                  title = "^Picture-in-Picture$";
                }
                {
                  app-id = "^google-chrome$";
                  title = "^Picture-in-Picture$";
                }
              ];
            }
            # Other floating windows
            {
              open-floating = true;
              matches = [
                {app-id = ".*float.*";}
                {app-id = "org\\.freedesktop\\.impl\\.portal\\.desktop\\..*";}
                {title = ".*float.*";}
                {title = "Extension: .*Bitwarden.*";}
                {app-id = "Rofi";}
                {app-id = "^org\\.kde\\.polkit-kde-authentication-agent-1$";}
                {
                  app-id = "^org\\.gnome\\.Nautilus$";
                  title = "^Open File$";
                }
                {
                  app-id = "^org\\.gnome\\.Nautilus$";
                  title = "^Select Export Location$";
                }
                {
                  app-id = "^python3$";
                  title = "^Buzz$";
                }
                {app-id = "^com\\.github\\.tenderowl\\.frog$";}
              ];
            }
            # Indicate screencasted windows with red colors
            {
              matches = [{is-window-cast-target = true;}];
              focus-ring = {
                active.color = "#f38ba8";
                inactive.color = "#7d0d2d";
              };
              border = {
                inactive.color = "#7d0d2d";
              };
              shadow = {
                color = "#7d0d2d70";
              };
              tab-indicator = {
                active.color = "#f38ba8";
                inactive.color = "#7d0d2d";
              };
            }
          ];

          # Gesture configuration
          gestures = {
            dnd-edge-workspace-switch = {
              trigger-height = 100;
              max-speed = 3000;
            };
            dnd-edge-view-scroll = {
              trigger-width = 100;
              max-speed = 3000;
            };
          };

          # Overview mode settings
          overview = {
            zoom = 0.4;
            backdrop-color = "#222222";
          };

          # Block notifications from screencasts
          # layer-rules = [
          #   {
          #     matches = [
          #       {namespace = "^notifications$";}
          #       {namespace = "^dunst$";}
          #     ];
          #     block-out-from = ["screencast"];
          #   }
          # ];
        };
      };
    };
  };
}
