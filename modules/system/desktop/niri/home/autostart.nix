{pkgs, ...}: {
  home.packages = with pkgs; [
    networkmanagerapplet
    blueman
    polkit_gnome
  ];

  programs.niri.settings.spawn-at-startup = [
    # Import environment variables for systemd and D-Bus
    {command = ["dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"];}
    {command = ["systemctl" "--user" "import-environment" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"];}
    {command = ["dbus-update-activation-environment" "--all"];}

    # Start xdg-desktop-portal-gnome for screencasting support
    {command = ["${pkgs.xdg-desktop-portal-gnome}/libexec/xdg-desktop-portal-gnome"];}

    # Launch apps via 'uwsm app' to integrate with systemd session management
    {command = ["uwsm app -- swww img ~/.wallpaper.png"];}
    {command = ["uwsm" "app" "--" "waybar"];}
    {command = ["uwsm" "app" "--" "nm-applet" "--indicator"];}
    {command = ["uwsm" "app" "--" "blueman-applet"];}
    {command = ["uwsm" "app" "--" "dunst"];}
    {command = ["uwsm" "app" "--" "vicinae" "server"];}
    {command = ["uwsm" "app" "--" "aw-qt"];}
    {command = ["uwsm" "app" "--" "polkit-gnome-authentication-agent-1"];}
    {command = ["uwsm" "app" "--" "xwayland-satellite"];}
  ];
}
