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
  '';

  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      pane size=1 borderless=true {
        plugin location="https://github.com/evgenymng/zellij-compact-bar/releases/latest/download/compact-bar.wasm"
      }

      children

      pane size=2 borderless=true {
        plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
          format_left   "#[fg=#89B4FA,bold]{session}"
          format_center "{tabs}"
          format_right  "{command_git_branch} {datetime}"
          format_space  ""

          border_enabled  "false"
          border_char     "─"
          border_format   "#[fg=#7b8496]{char}"
          border_position "bottom"

          hide_frame_for_single_pane "true"

          tab_normal   "#[fg=#6C7086,bg=#181825] {index} {name} "
          tab_active   "#[fg=#9399B2,bg=#11111B,bold,italic] {index} {name} "
        }
      }
    }
    session_manager {
      plugin location="https://github.com/blank2121/zellij-jump-list/releases/latest/download/zellij-jump-list.wasm" {
        jump_tool "zoxide"
      }
    }
  '';
}
