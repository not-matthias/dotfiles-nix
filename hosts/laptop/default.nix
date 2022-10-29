{...}: {
  imports =
    [(import ./hardware-configuration.nix)]
    # ++ (import ../../modules/desktop/i3)
    ++ [(import ../../modules/desktop/gnome)]
    ++ (import ../../modules/hardware)
    ++ (import ../../modules/desktop/virtualization);

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
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
      luks.devices."luks-f1073b9e-82f8-4202-bc02-d74cefbb60d8".device = "/dev/disk/by-uuid/f1073b9e-82f8-4202-bc02-d74cefbb60d8";
      luks.devices."luks-f1073b9e-82f8-4202-bc02-d74cefbb60d8".keyFile = "/crypto_keyfile.bin";
    };
  };

  #temporary bluetooth fix
  systemd.tmpfiles.rules = [
    "d /var/lib/bluetooth 700 root root - -"
  ];
  systemd.targets."bluetooth".after = ["systemd-tmpfiles-setup.service"];
}
