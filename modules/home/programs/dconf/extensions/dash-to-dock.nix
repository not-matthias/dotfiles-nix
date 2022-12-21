{pkgs, ...}: {
  home.packages = with pkgs; [
    gnomeExtensions.dash-to-dock
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      autohide-in-fullscreen = false;
      intellihide-mode = "MAXIMIZED_WINDOWS";
      dash-max-icon-size = 36;

      # Only show windows from current workspace
      isolate-workspaces = true;

      show-apps-at-top = false;
      show-favorites = true;
      show-mounts = false;
      show-running = true;
      show-trash = false;
    };
  };
}
