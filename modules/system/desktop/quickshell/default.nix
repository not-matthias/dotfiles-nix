{
  pkgs,
  lib,
  config,
  quickshell,
  ...
}:
with lib; let
  cfg = config.desktop.quickshell;
in {
  options.desktop.quickshell = {
    enable = mkEnableOption "Enable Quickshell";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      quickshell.packages.${pkgs.system}.default
    ];

    # Ensure Qt and Wayland support
    environment.sessionVariables = {
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };

    # Enable required services for Qt/Wayland
    services.dbus.enable = true;

    # Ensure XDG portal is available for Qt applications
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };
}
