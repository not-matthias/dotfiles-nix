{
  pkgs,
  unstable,
  user,
  lib,
  flakes,
  ...
}: {
  imports = [(import ./hardware-configuration.nix)];

  home-manager.users.${user} = {
    home.packages = with pkgs; [
      unstable.zed-editor
      unstable.feishin
      unstable.vscode

      vlc
      evince
      gwenview
      nautilus
      file-roller
      gnome-text-editor
      unstable.anki
      obs-studio
      calibre
      zotero
      mission-center

      flakes.zen-browser.packages."${system}".default
    ];

    programs = {
      gitui.enable = true;
      alacritty.enable = true;
      waybar.enable = true;
      firefox.enable = true;
    };

    services = {
      activitywatch.enable = false;
      dunst.enable = true;
    };
  };

  programs = {
    noisetorch.enable = true;
    fcitx5.enable = true;
    neovim.enable = true;
  };

  services = {
    vpn.enable = true;
    safeeyes.enable = true;
    printing.enable = true;
    navidrome = {
      enable = true;
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
    };
    adguardhome.useDns = true;
    caddy.enable = true;
  };

  hardware = {
    powersave.enable = true;
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
    qemu.enable = true;
    vfio = {
      enable = true;
      IOMMUType = "intel";
      enableNestedVirt = true;
    };
  };
  desktop = {
    hyprland.enable = true;
    fonts.enable = true;
  };

  # Backup the important folders
  services.restic.backups.nas.paths = [
    # "/home/${user}/Documents/temp"
    # "/home/${user}/Pictures"
    # TODO: What to backup?
  ];

  # age.identityPaths = ["/home/${user}/.ssh/id_rsa"];
  # home.sessionVariables = {
  #                  SECRET_VALUE = ''
  #                    $(${pkgs.coreutils}/bin/cat ${config.age.secrets.secret1.path})
  #                  '';
  #                };

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
