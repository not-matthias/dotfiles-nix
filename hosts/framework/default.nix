{...}: {
  imports = [(import ./hardware-configuration.nix)];

  # https://wiki.archlinux.org/title/Solid_state_drive#TRIM
  # - SSDs benefit from informing the disk controller when blocks of memory are free to be reused
  services.fstrim.enable = true;
  services.printing.enable = true;

  programs = {
    noisetorch.enable = true;
    #vscode.enable = true;
  };

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };
  hardware = {
    powersave.enable = true;
    intel.enable = true;
  };
  virtualisation.vfio = {
    enable = true;
    IOMMUType = "intel";
    enableNestedVirt = true;
  };
  desktop.hyprland.enable = true;

  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd = {
      # Setup keyfile
      secrets."/crypto_keyfile.bin" = null;

      # Enable swap on luks
      luks.devices."luks-482bfe5c-c987-4a97-9c07-b8cd312cabb5".device = "/dev/disk/by-uuid/482bfe5c-c987-4a97-9c07-b8cd312cabb5";
      luks.devices."luks-482bfe5c-c987-4a97-9c07-b8cd312cabb5".keyFile = "/crypto_keyfile.bin";
    };
  };
}
