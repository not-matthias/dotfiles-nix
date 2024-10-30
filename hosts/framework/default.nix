{
  pkgs,
  unstable,
  user,
  ...
}: {
  imports = [(import ./hardware-configuration.nix)];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      signal-desktop
      unstable.zed-editor
      vscodium

      vlc
      evince
      gwenview
      gnome.nautilus
      gnome.file-roller
      gnome-text-editor
      obs-studio
      unstable.anki
      calibre
      zotero
    ];

    services.activitywatch.enable = true;
  };

  services = {
    printing.enable = true;
    system76-scheduler.enable = true;
  };

  programs = {
    noisetorch.enable = true;
    steam.enable = false;
  };

  hardware = {
    powersave.enable = true;
    intel.enable = true;
    bluetooth.enable = true;
    sound.enable = true;
    ssd.enable = true;
    fingerprint.enable = true;
    system76.enableAll = true;
  };

  virtualisation.vfio = {
    enable = true;
    IOMMUType = "intel";
    enableNestedVirt = true;
  };
  desktop.hyprland.enable = true;

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };

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
