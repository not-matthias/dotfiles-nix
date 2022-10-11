{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [(import ./dconf.nix)];

  services = {
    xserver = {
      enable = true;

      layout = "us";
      xkbOptions = "eurosign:e";
      libinput.enable = true;
      wacom.enable = true;

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
  };

  hardware.pulseaudio.enable = false;
  environment.systemPackages = with pkgs; [
    gnome.adwaita-icon-theme
    xclip
    xorg.xev
    xorg.xkill
    xorg.xrandr
  ];
}
