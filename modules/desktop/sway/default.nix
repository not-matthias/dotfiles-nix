{pkgs, ...}: {
  security.polkit.enable = true;

  hardware.opengl = {
    enable = true;
  };

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      wf-recorder
      mako # notification daemon
      bemenu # wayland clone of dmenu
      grim # screenshot functionality
      slurp # screenshot functionality
      #kanshi

      wayland
      xwayland
      gsettings-desktop-schemas
    ];
    wrapperFeatures.gtk = true;
  };

  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    displayManager.sessionPackages = [pkgs.sway];
    libinput.enable = true;
  };
}
