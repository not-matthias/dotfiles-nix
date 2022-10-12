{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.dconf.enable = true;

  services = {
    xserver = {
      enable = true;

      layout = "us";
      xkbOptions = "eurosign:e";
      libinput.enable = true;

      displayManager = {
        gdm = {
          enable = true;
        };
      };
      desktopManager = {
        gnome = {
          enable = true;
        };
      };
    };
    udev.packages = with pkgs; [
      gnome.gnome-settings-daemon
    ];
  };

  hardware.pulseaudio.enable = false;

  environment = {
    systemPackages = with pkgs; [
      gnome.adwaita-icon-theme
      gnomeExtensions.appindicator
      gnomeExtensions.pop-shell
    ];
  };
}
