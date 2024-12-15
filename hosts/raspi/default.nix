{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "raspi";
    networkmanager.enable = true;
  };

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;

  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
}
