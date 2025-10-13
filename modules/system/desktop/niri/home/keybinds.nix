# Keybind philosophy:
# - Able to use it on my left hand only, this way I can keep my right hand on my mouse.
#
# Workspace rules:
# - Most commonly used workspace should be closer to 1 (e.g. browser is 1)
# - Coding: Might require multiple workspaces -> different sessions/projects
#
# TODO:
# 1: browser (work)
# 2: music
# 3:
#
# I could remap: 0 to 7 and 9 to 6 -> this way the workspaces are closer -> make sthe overview easier
let
  mod = "Alt";
  mod1 = "Super";
in {
  programs.niri.settings.binds = {
    # Basic application binds
    "${mod}+Q".action.spawn = ["alacritty"];
    "${mod}+C".action.close-window = [];
    "${mod}+M".action.quit = [];
    "${mod}+E".action.spawn = ["nemo"];
    "${mod}+V".action.toggle-window-floating = [];
    "${mod}+R".action.spawn = ["vicinae" "toggle"];
    "${mod}+F".action.fullscreen-window = [];
    "${mod1}+L".action.spawn = ["swaylock" "-f" "-c" "000000"];

    # Overview mode
    "${mod}+O".action.toggle-overview = [];
    "${mod}+G".action.toggle-overview = [];

    # Tabbed column functionality
    "${mod}+T".action.toggle-column-tabbed-display = [];

    # Column navigation with HL keys
    "${mod}+H".action.focus-column-or-monitor-left = [];
    "${mod}+L".action.focus-column-or-monitor-right = [];
    # Workspace navigation with JK and WS keys
    "${mod}+K".action.focus-workspace-up = [];
    "${mod}+J".action.focus-workspace-down = [];
    "${mod}+W".action.focus-workspace-up = [];
    "${mod}+S".action.focus-workspace-down = [];
    # Column navigation with AD keys
    "${mod}+A".action.focus-column-or-monitor-left = [];
    "${mod}+D".action.focus-column-or-monitor-right = [];
    "${mod}+BracketLeft".action.focus-column-left = [];
    "${mod}+BracketRight".action.focus-column-right = [];

    # Screenshot keybindings
    "Print".action.screenshot-screen = [];
    "${mod}+Shift+S".action.screenshot = [];
    "${mod}+Shift+O".action.spawn = ["bash" "-c" "grim -g \"$(slurp)\" \"tmp.png\" && tesseract -l eng \"tmp.png\" - | wl-copy && rm \"tmp.png\""];

    # Misc
    "Ctrl+Period".action.spawn = ["wofi-emoji"];
    "Super+Slash".action.show-hotkey-overlay = [];

    # Column resizing
    "${mod}+Ctrl+I".action.consume-window-into-column = [];
    "${mod}+Ctrl+O".action.expel-window-from-column = [];
    "${mod}+Comma".action.consume-or-expel-window-left = [];
    "${mod}+Period".action.consume-or-expel-window-right = [];

    # Window movements:
    "${mod}+Shift+H".action.move-window-to-monitor-left = [];
    "${mod}+Shift+L".action.move-window-to-monitor-right = [];
    "${mod}+Shift+K".action.move-window-to-workspace-up = [];
    "${mod}+Shift+J".action.move-window-to-workspace-down = [];

    # Column and window sizing
    "${mod}+Shift+R".action.reset-window-height = [];
    "${mod}+Shift+F".action.maximize-column = [];

    # Column width resizing
    "${mod}+Equal".action.set-column-width = "+10%";
    "${mod}+Minus".action.set-column-width = "-10%";
    "${mod}+Shift+Equal".action.set-window-height = "+10%";
    "${mod}+Shift+Minus".action.set-window-height = "-10%";

    # Column management
    "${mod}+Ctrl+Left".action.move-column-left = [];
    "${mod}+Ctrl+Right".action.move-column-right = [];
    "${mod}+Ctrl+H".action.move-column-left = [];
    "${mod}+Ctrl+L".action.move-column-right = [];

    # Volume controls
    "XF86AudioRaiseVolume".action.spawn = ["amixer" "set" "Master" "5%+"];
    "XF86AudioLowerVolume".action.spawn = ["amixer" "set" "Master" "5%-"];
    "XF86AudioMute".action.spawn = ["amixer" "set" "Master" "toggle"];

    # Brightness controls
    "XF86MonBrightnessUp".action.spawn = ["brightnessctl" "set" "10%+"];
    "XF86MonBrightnessDown".action.spawn = ["brightnessctl" "set" "10%-"];

    # Media controls
    "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
    "XF86AudioNext".action.spawn = ["playerctl" "next"];
    "XF86AudioPrev".action.spawn = ["playerctl" "previous"];
    "XF86AudioStop".action.spawn = ["playerctl" "stop"];

    "${mod}+Tab".action.focus-workspace-previous = [];

    # Workspace switching
    "${mod}+1".action.focus-workspace = 1;
    "${mod}+2".action.focus-workspace = 2;
    "${mod}+3".action.focus-workspace = 3;
    "${mod}+4".action.focus-workspace = 4;
    "${mod}+5".action.focus-workspace = 5;
    "${mod}+6".action.focus-workspace = 6;
    "${mod}+7".action.focus-workspace = 7;
    "${mod}+8".action.focus-workspace = 8;
    "${mod}+9".action.focus-workspace = 9;
    "${mod}+Y".action.focus-workspace = "scratchpad";

    # Move window to workspace
    "${mod}+Shift+1".action.move-window-to-workspace = 1;
    "${mod}+Shift+2".action.move-window-to-workspace = 2;
    "${mod}+Shift+3".action.move-window-to-workspace = 3;
    "${mod}+Shift+4".action.move-window-to-workspace = 4;
    "${mod}+Shift+5".action.move-window-to-workspace = 5;
    "${mod}+Shift+6".action.move-window-to-workspace = 6;
    "${mod}+Shift+7".action.move-window-to-workspace = 7;
    "${mod}+Shift+8".action.move-window-to-workspace = 8;
    "${mod}+Shift+9".action.move-window-to-workspace = 9;
    "${mod}+Shift+Y".action.move-window-to-workspace = "scratchpad";
  };
}
