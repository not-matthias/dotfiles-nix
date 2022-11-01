{pkgs, ...}: {
  programs.dconf.enable = true;

  services = {
    xserver = {
      enable = true;

      layout = "us";
      xkbOptions = "";
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

  environment = {
    systemPackages = with pkgs; [
      xdg-desktop-portal-gnome
      gnome.adwaita-icon-theme
      gnome.gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.pop-shell
      gnomeExtensions.paperwm
    ];
  };
}
