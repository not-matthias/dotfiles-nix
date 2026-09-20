{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    networkmanagerapplet
    blueman
    polkit_gnome
  ];

  programs.niri.settings.spawn-at-startup = [
    # Import environment variables for systemd and D-Bus
    {command = ["dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "NIRI_SOCKET"];}
    {command = ["systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "NIRI_SOCKET"];}
    {command = ["dbus-update-activation-environment" "--all"];}
    {command = ["systemctl" "--user" "restart" "quickshell.service"];}

    # Launch apps via 'uwsm app' to integrate with systemd session management
    {command = ["uwsm" "app" "--" "awww" "img" "${config.home.homeDirectory}/.wallpaper.png"];}
    {command = ["uwsm" "app" "--" "nm-applet" "--indicator"];}
    {command = ["uwsm" "app" "--" "blueman-applet"];}
    {command = ["uwsm" "app" "--" "dunst"];}
    {command = ["uwsm" "app" "--" "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"];}
    {command = ["uwsm" "app" "--" "xwayland-satellite"];}
  ];
}
