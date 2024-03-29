{pkgs, ...}: {
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
      gnome.gnome-tweaks
      gnomeExtensions.appindicator
      gnomeExtensions.pop-shell
      gnomeExtensions.paperwm
    ];
  };

  environment.gnome.excludePackages =
    (with pkgs; [
      gnome-photos
      gnome-tour
    ])
    ++ (with pkgs.gnome; [
      cheese # webcam tool
      gnome-music
      gnome-terminal
      gedit # text editor
      epiphany # web browser
      geary # email reader
      gnome-characters
      totem # video player
      tali # poker game
      iagno # go game
      hitori # sudoku game
      atomix # puzzle game
    ]);
}
