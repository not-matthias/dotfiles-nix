{...}: {
  imports =
    [(import ./hardware-configuration.nix)]
    # ++ [(import ../../modules/desktop/sway)]
    ++ [(import ../../modules/desktop/gnome)]
    ++ (import ../../modules/desktop/virtualization);

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
  };

  virtualisation = {
    vfio = {
      enable = true;
      IOMMUType = "amd";
      devices = ["10de:1f08" "10de:10f9" "10de:1ada" "10de:1adb"];
      ignoreMSRs = true;
      blacklistNvidia = true;
      enableNestedVirt = true;
    };
  };

  # Lots of these are from the default `configuration.nix`
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
      luks.devices."luks-08f4eec8-fe32-472a-8e3c-4213b620923b".device = "/dev/disk/by-uuid/08f4eec8-fe32-472a-8e3c-4213b620923b";
      luks.devices."luks-08f4eec8-fe32-472a-8e3c-4213b620923b".keyFile = "/crypto_keyfile.bin";
    };
  };
}
