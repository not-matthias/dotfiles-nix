{
  unstable,
  lib,
  osConfig ? {},
  ...
}: let
  datetimeTimezone = lib.optionalString (osConfig ? time.timeZone) "datetime_timezone \"${osConfig.time.timeZone}\"";
in {
  programs.fish.interactiveShellInit = ''
    # Wrap zellij to auto-name sessions (rename-session is broken inside zellij, so we set it at launch)
    function zellij --wraps=zellij
      if test (count $argv) -eq 0
        set -l name
        if set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
          set name (basename $git_root)
        else
          set name (basename $PWD)
        end
        command zellij attach --create "$name"
      else
        command zellij $argv
      end
    end

  '';
  programs.zellij = {
    enable = true;
    package = unstable.zellij;
  };

  xdg.configFile."zellij/config.kdl".text = ''
    default_layout "default"
    mouse_mode true
    simplified_ui true
    pane_frames false

    keybinds {
      // Free Ctrl+O so it passes through to Claude/pi/other agents
      // (default zellij binding is SwitchToMode "Session")
      unbind "Ctrl o"

      normal {
        bind "Ctrl b" { SwitchToMode "Tmux"; }
        bind "Ctrl f" {
          LaunchOrFocusPlugin "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij-forgot.wasm" {
            floating true
          }
        }
      }

      tmux {
        // Match Herdr's prefix shortcuts; each action returns to normal input.
        bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
        bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
        bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
        bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
        bind "v" { NewPane "Right"; SwitchToMode "Normal"; }
        bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
        bind "c" { NewTab; SwitchToMode "Normal"; }
        bind "n" { GoToNextTab; SwitchToMode "Normal"; }
        bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
        bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "Ctrl b" { Write 2; SwitchToMode "Normal"; }
        bind "1" { GoToTab 1; SwitchToMode "Normal"; }
        bind "2" { GoToTab 2; SwitchToMode "Normal"; }
        bind "3" { GoToTab 3; SwitchToMode "Normal"; }
        bind "4" { GoToTab 4; SwitchToMode "Normal"; }
        bind "5" { GoToTab 5; SwitchToMode "Normal"; }
        bind "6" { GoToTab 6; SwitchToMode "Normal"; }
        bind "7" { GoToTab 7; SwitchToMode "Normal"; }
        bind "8" { GoToTab 8; SwitchToMode "Normal"; }
        bind "9" { GoToTab 9; SwitchToMode "Normal"; }
      }
    }

    ui {
      pane_frames {
        rounded_corners false
      }
    }

    session_manager {
      plugin location="https://github.com/blank2121/zellij-jump-list/releases/latest/download/zellij-jump-list.wasm" {
        jump_tool "zoxide"
      }
    }
  '';

  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      pane

      pane size=2 borderless=true {
        plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
          format_left  "#[fg=0,bg=10][{session}]  {tabs}"
          format_right "#[fg=0,bg=10]{datetime}"
          format_space "#[bg=10]"

          hide_frame_for_single_pane "true"

          tab_normal   "{index}:{name}  "
          tab_active   "{index}:{name}* "

          datetime          " {format} "
          datetime_format   "%H:%M %d-%b-%y"
          ${datetimeTimezone}
        }
      }
    }
  '';
}
