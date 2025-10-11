{
  programs.niri.settings.input = {
    workspace-auto-back-and-forth = true;
    focus-follows-mouse.enable = true;
    warp-mouse-to-focus.enable = false;
    keyboard.xkb = {
      layout = "us,de";
      options = "grp:win_space_toggle";
    };
    touchpad = {
      tap = true;
      dwt = true;
      dwtp = true;
      natural-scroll = true;
      accel-speed = 0.0;
      accel-profile = "adaptive";
    };
    mouse.accel-profile = "flat";
  };
}
