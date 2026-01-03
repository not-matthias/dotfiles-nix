{
  pkgs,
  lib,
  nixos-hardware,
  user,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.raspberry-pi-4
  ];

  stylix.enable = true;
  home-manager.users.${user} = {
    home.stateVersion = "25.05";
    programs = {
      nixvim.enable = true;
      claude.enable = true;
      btop.enable = true;
    };
  };

  networking = {
    hostName = "raspi";
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
    };
  };

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;

  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
}
