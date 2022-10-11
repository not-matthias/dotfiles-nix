{
  config,
  pkgs,
  user,
  ...
}: {
  imports = [(import ./hardware-configuration.nix)];

  # TODO: Window Manager, Docker, Hardware Devices (Bluetooth)

  programs = {
    dconf.enable = true;
    light.enable = true;
  };

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
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
}
