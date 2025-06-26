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
      unstable.supersonic
      unstable.vscode
      unstable.obsidian
      unstable.todoist-electron
      google-chrome

      vlc
      evince
      kdePackages.gwenview
      nautilus
      file-roller
      gnome-text-editor
      unstable.anki
      calibre
      fastfetch

      slack
      awscli2
      flakes.zen-browser.packages."${system}".default

      # Language servers
      taplo
      nil
      nixd
    ];
    programs = {
      walker = {
        enable = true;
        runAsService = true;
      };
      granted.enable = true;
      kitty.enable = true;
      alacritty.enable = true;
      waybar.enable = true;
      nixvim.enable = true;

      gitui.enable = true;
      firefox.enable = false;

      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-vaapi
          obs-vkcapture
          obs-gstreamer
          obs-pipewire-audio-capture
          wlrobs
          obs-backgroundremoval
        ];
      };
    };

    services = {
      activitywatch.enable = true;
      dunst.enable = true;
      gpg-agent.enable = true;
    };

    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  programs = {
    fcitx5.enable = true;
    nix-ld.enable = true;
    noisetorch.enable = true;
  };

  services = {
    system76-scheduler = {
      enable = true;
      assignments = {
        nix-builds = {
          nice = 15;
          class = "batch";
          ioClass = "idle";
          matchers = [
            "nix-daemon"
          ];
        };
      };
    };
    earlyoom.enable = true;
    audiobookshelf = {
      enable = true;
      audioFolder = "/home/${user}/Audiobooks";
    };
    vpn.enable = true;
    safeeyes.enable = true;
    navidrome = {
      enable = true;
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
    };
    caddy.enable = true;
    yubikey.enable = true;
  };

  hardware = {
    powersave.enable = true;
    bluetooth.enable = true;
    sound.enable = true;
    ssd.enable = true;
    fingerprint.enable = true;
  };

  virtualisation = {
    podman.enable = true;
    docker.enable = true; # Required for work (exec service)
  };
  desktop = {
    hyprland = {
      enable = true;
      useIntel = true;
    };
    fonts.enable = true;
  };

  # Backup the important folders
  services.restic.backups.nas.paths = [
    # "/home/${user}/Documents/temp"
    # "/home/${user}/Pictures"
    # TODO: What to backup?
  ];

  age.identityPaths = ["/home/${user}/.ssh/id_rsa"];

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
