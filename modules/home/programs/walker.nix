{
  flakes,
  pkgs,
  lib,
  ...
}: {
  imports = [flakes.walker.homeManagerModules.default];

  programs.walker = {
    # See default config: https://github.com/abenz1267/walker/main/internal/config/config.default.toml
    config = {
      activation_mode = {
        disabled = false;
        use_alt = true;
        activation_mode.labels = "12345678";
      };
      force_keyboard_focus = true;

      keys.activation-modifiers = {
        alternate = "ctrl";
      };

      disabled = ["clipboard"];
      builtins = {
        bookmarks = {
          switcher_only = false;
          entries = [
            {
              label = "Nixpkgs Search";
              url = "https://search.nixos.org";
              keywords = ["nixpkgs"];
            }
          ];
        };

        finder = {
          prefix = "?";
          use_fd = true;
          fd_flags = "--no-hidden --ignore-vcs --type dir";
          ignore_gitignore = true;
          switcher_only = true;
        };

        websearch = {
          keep_selection = true;
          weight = 5;

          entries = [
            {
              name = "Brave Search";
              url = "https://search.brave.com/search?q=%TERM%";
            }
          ];
        };

        runner = {
          prefix = ">";
          switcher_only = true;
        };
      };

      plugins = [
        {
          name = "auto-cpufreq";
          switcher_only = false;

          entries = [
            {
              exec = "sudo auto-cpufreq --force powersave";
              label = "Powersave";
            }
            {
              exec = "sudo auto-cpufreq --force performance";
              label = "Performance";
            }
          ];
        }
        {
          keep_sort = false;
          name = "power";
          placeholder = "Power";
          recalculate_score = true;
          show_icon_when_single = true;
          switcher_only = true;

          entries = [
            {
              exec = "hyprctl dispatch exit --reboot";
              icon = "system-reboot";
              label = "Reboot";
            }
            {
              exec = "hyprctl dispatch exit --shutdown";
              icon = "system-shutdown";
              label = "Shutdown";
            }
            {
              exec = "hyprctl dispatch exit";
              icon = "system-log-out";
              label = "Logout";
            }
            {
              label = "Lock";
              icon = "system-lock-screen";
              exec = "playerctl --all-players pause  & swaylock -f -c 000000";
            }
          ];
        }
        {
          name = "kill";
          prefix = "!";
          src_once = "ps -u $USER -o comm= | sort -u";
          cmd = "pkill -f %RESULT%";
        }
        {
          name = "Open Zed in";
          src_once = "fd $HOME -type d --ignore-vcs";
          cmd = "zed %RESULT%";
        }
      ];

      terminal = "alacritty";
      websearch.prefix = "?";
      switcher.prefix = "/";

      keys = {
        trigger_labels = "ctrl";
        accept_typeahead = ["tab"];
        next = [
          "ctrl j"
          "down"
        ];
        prev = [
          "ctrl k"
          "up"
        ];
        resume_query = ["ctrl r"];
        toggle_exact_search = ["ctrl m"];
      };
    };
  };
  home.packages = [pkgs.libqalculate];

}
