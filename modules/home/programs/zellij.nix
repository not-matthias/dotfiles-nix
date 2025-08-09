{unstable, ...}: {
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
      normal {
        bind "Ctrl b" { SwitchToMode "Tmux"; }
        bind "Ctrl j" {
          LaunchOrFocusPlugin "zellij:session-manager" {
            floating true
            move_to_focused_tab true
          }
        }
        bind "Ctrl s" {
          LaunchOrFocusPlugin "https://github.com/laperlej/zellij-sessionizer/releases/latest/download/zellij-sessionizer.wasm" {
            floating true
          }
        }
        bind "Ctrl f" {
          LaunchOrFocusPlugin "https://github.com/karimould/zellij-forgot/releases/latest/download/zellij-forgot.wasm" {
            floating true
          }
        }
      }

      tmux {
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
          datetime_timezone "Europe/Vienna"
        }
      }
    }
  '';
}
