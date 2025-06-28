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

    ui {
      pane_frames {
        rounded_corners false
      }
    }

    keybinds {
      normal {
        bind "Ctrl b" { SwitchToMode "Tmux"; }
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

  '';

  # TODO:
  # - https://github.com/karimould/zellij-forgot
  # - https://github.com/roberte777/zesh
  # - https://github.com/evgenymng/zellij-compact-bar
  # - https://github.com/blank2121/zellij-jump-list
  # - https://github.com/zellij-org/awesome-zellij
  # - https://github.com/rvcas/room
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
        default_tab_template {
          children

          pane size=1 borderless=true {
            plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
                format_left   "{mode} #[fg=#89B4FA,bold]{session}"
                format_center "{tabs}"

                mode_normal  "#[bg=blue] "
                mode_tmux    "#[bg=#ffc387] "
            }
          }
        }
      }
  '';

  # format_left   "{mode} #[fg=#89B4FA,bold]{session}"
  # format_center "{tabs}"
  # format_right  "{command_git_branch} {datetime}"
  # format_space  ""

  # border_enabled  "false"
  # border_char     "─"
  # border_format   "#[fg=#7b8496]{char}"
  # border_position "bottom"

  # hide_frame_for_single_pane "true"

  # xdg.configFile."zellij/layouts/default.kdl".text = ''
  #   load_plugins {
  #       "https://github.com/dj95/zjstatus/releases/latest/download/zjframes.wasm" {
  #           hide_frame_for_single_pane       "true"
  #           hide_frame_except_for_search     "true"
  #           hide_frame_except_for_scroll     "true"
  #           hide_frame_except_for_fullscreen "true"
  #       }
  #   }

  #   keybinds {
  #       normal clear-defaults=true {
  #           // https://shoukoo.github.io/blog/zellij-love-neovim/
  #           bind "Ctrl b" { SwitchToMode "Tmux"; }

  #           // bind "Esc" { SwitchToMode "Normal"; }
  #           // bind "g" { SwitchToMode "Locked"; }
  #           // bind "p" { SwitchToMode "Pane"; }
  #           // bind "t" { SwitchToMode "Tab"; }
  #           // bind "n" { SwitchToMode "Resize"; }
  #           // bind "h" { SwitchToMode "Move"; }
  #           // bind "s" { SwitchToMode "Scroll"; }
  #           // bind "o" { SwitchToMode "Session"; }
  #           // bind "q" { Quit; }
  #       }
  #   }

  #   layout {
  #       pane size=1 borderless=true {
  #           plugin location="https://github.com/evgenymng/zellij-compact-bar/releases/download/1.0.0/compact-bar.wasm" {
  #               inactive_color "#505050"
  #               text_background_color "#1e1e1e"
  #               background_color "#1e1e1e"
  #               dot "•"
  #               dot_locked_color "#404040"
  #               dot_normal_color "#70a040"
  #               dot_action_color "#ffb070"
  #           }
  #       }

  #       // pane size=1 borderless=true {
  #       //     plugin location="status-bar"
  #       // }

  #       children

  #       pane size=1 borderless=true {
  #           plugin location="https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" {
  #               format_left   "{mode} #[fg=#89B4FA,bold]{session}"
  #               format_center "{tabs}"
  #               format_right  "{command_git_branch} {datetime}"
  #               format_space  ""
  #           }
  #       }
  #   }
  # '';

  # default_layout "compact"
  # layout {
  #   pane borderless=true
  #   pane size=1 borderless=true {
  #       plugin location="zjframes"
  #   }
  # }
  #simplified_ui true
  #pane_frames false
}
