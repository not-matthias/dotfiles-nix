{...}: {
  imports = [(import ./hardware-configuration.nix)];

  services = {
    printing.enable = true;
  };

  services.system76-scheduler = {
    enable = true;
  };
  hardware.system76.enableAll = true;

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
    bluetooth.enable = true;
    ssd.enable = true;
    fingerprint.enable = true;
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
