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
{
  programs.niri.settings.binds = {
    # Basic application binds
    "Alt+Q".action.spawn = ["alacritty"];
    "Alt+C".action.close-window = [];
    "Alt+M".action.quit = [];
    "Alt+E".action.spawn = ["nemo"];
    "Alt+V".action.toggle-window-floating = [];
    "Alt+R".action.spawn = ["vicinae" "toggle"];
    "Alt+F".action.fullscreen-window = [];
    "Super+L".action.spawn = ["swaylock" "-f" "-c" "000000"];

    # Overview mode
    "Alt+O".action.toggle-overview = [];
    "Alt+G".action.toggle-overview = [];

    # Tabbed column functionality
    "Alt+T".action.toggle-column-tabbed-display = [];

    # Column navigation with HL keys
    "Alt+H".action.focus-column-or-monitor-left = [];
    "Alt+L".action.focus-column-or-monitor-right = [];
    # Workspace navigation with JK and WS keys
    "Alt+K".action.focus-workspace-up = [];
    "Alt+J".action.focus-workspace-down = [];
    "Alt+W".action.focus-workspace-up = [];
    "Alt+S".action.focus-workspace-down = [];
    # Column navigation with AD keys
    "Alt+A".action.focus-column-or-monitor-left = [];
    "Alt+D".action.focus-column-or-monitor-right = [];
    "Alt+BracketLeft".action.focus-column-left = [];
    "Alt+BracketRight".action.focus-column-right = [];

    # Screenshot keybindings
    "Print".action.screenshot-screen = [];
    "Alt+Shift+S".action.screenshot = [];
    "Alt+Shift+O".action.spawn = ["bash" "-c" "grim -g \"$(slurp)\" \"tmp.png\" && tesseract -l eng \"tmp.png\" - | wl-copy && rm \"tmp.png\""];

    # Misc
    "Ctrl+Period".action.spawn = ["wofi-emoji"];
    "Super+Slash".action.show-hotkey-overlay = [];

    # Column resizing
    "Alt+Ctrl+I".action.consume-window-into-column = [];
    "Alt+Ctrl+O".action.expel-window-from-column = [];
    "Alt+Comma".action.consume-or-expel-window-left = [];
    "Alt+Period".action.consume-or-expel-window-right = [];

    # Window movements:
    "Alt+Shift+H".action.move-window-to-monitor-left = [];
    "Alt+Shift+L".action.move-window-to-monitor-right = [];
    "Alt+Shift+K".action.move-window-to-workspace-up = [];
    "Alt+Shift+J".action.move-window-to-workspace-down = [];

    # Column and window sizing
    "Alt+Shift+R".action.reset-window-height = [];
    "Alt+Shift+F".action.maximize-column = [];

    # Column width resizing
    "Alt+Equal".action.set-column-width = "+10%";
    "Alt+Minus".action.set-column-width = "-10%";
    "Alt+Shift+Equal".action.set-window-height = "+10%";
    "Alt+Shift+Minus".action.set-window-height = "-10%";

    # Column management
    "Alt+Ctrl+Left".action.move-column-left = [];
    "Alt+Ctrl+Right".action.move-column-right = [];
    "Alt+Ctrl+H".action.move-column-left = [];
    "Alt+Ctrl+L".action.move-column-right = [];

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

    "Alt+Tab".action.focus-workspace-previous = [];

    # Workspace switching
    "Alt+1".action.focus-workspace = 1;
    "Alt+2".action.focus-workspace = 2;
    "Alt+3".action.focus-workspace = 3;
    "Alt+4".action.focus-workspace = 4;
    "Alt+5".action.focus-workspace = 5;
    "Alt+6".action.focus-workspace = 6;
    "Alt+7".action.focus-workspace = 7;
    "Alt+8".action.focus-workspace = 8;
    "Alt+9".action.focus-workspace = 9;
    "Alt+Y".action.focus-workspace = "scratchpad";

    # Move window to workspace
    "Alt+Shift+1".action.move-window-to-workspace = 1;
    "Alt+Shift+2".action.move-window-to-workspace = 2;
    "Alt+Shift+3".action.move-window-to-workspace = 3;
    "Alt+Shift+4".action.move-window-to-workspace = 4;
    "Alt+Shift+5".action.move-window-to-workspace = 5;
    "Alt+Shift+6".action.move-window-to-workspace = 6;
    "Alt+Shift+7".action.move-window-to-workspace = 7;
    "Alt+Shift+8".action.move-window-to-workspace = 8;
    "Alt+Shift+9".action.move-window-to-workspace = 9;
    "Alt+Shift+Y".action.move-window-to-workspace = "scratchpad";
  };
}
