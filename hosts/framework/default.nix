{
  pkgs,
  unstable,
  user,
  lib,
  ...
}: {
  imports = [(import ./hardware-configuration.nix)];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      unstable.zed-editor
      vscodium
      beeper

      vlc
      evince
      gwenview
      gnome.nautilus
      gnome.file-roller
      gnome-text-editor
      unstable.anki
      obs-studio
      calibre
      zotero
      mission-center
      unstable.feishin # Music player
    ];

    services.activitywatch.enable = true;
  };

  services = {
    printing.enable = true;
    system76-scheduler.enable = true;
    adguard.enableDns = true;
    navidrome.enable = true;
    firefly-iii.enable = true;
  };

  programs = {
    noisetorch.enable = true;
    steam.enable = false;
  };

  hardware = {
    powersave.enable = true;
    # FIXME: Do we even need this with nixos-hardware?
    # intel.enable = true;
    bluetooth.enable = true;
    sound.enable = true;
    ssd.enable = true;
    fingerprint.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      enableNvidia = false;
    };
    vfio = {
      enable = true;
      IOMMUType = "intel";
      enableNestedVirt = true;
    };
  };
  desktop.hyprland.enable = true;

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
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
