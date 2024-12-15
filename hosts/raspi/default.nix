{
  pkgs,
  nixos-hardware,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.raspberry-pi-4
  ];

programs.neovim.enable = true;

  networking = {
    hostName = "raspi";
    networkmanager.enable = true;
  };

  #hardware = {
#    #raspberry-pi."4".apply-overlays-dtmerge.enable = true;
#    deviceTree = {
#     enable = true;
#     filter = "*rpi-4-*.dtb";
#j  };
#  };
  console.enable = true;
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
