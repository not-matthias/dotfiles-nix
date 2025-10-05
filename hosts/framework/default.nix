{
  pkgs,
  unstable,
  user,
  lib,
  config,
  flakes,
  ...
}: {
  imports = [
    (import ./hardware-configuration.nix)
  ];
  home-manager.users.${user} = {
    home.stateVersion = "22.05";
    home.packages = with pkgs; [
      unstable.zed-editor
      vscode
      obsidian
      bun
      google-chrome
      notepad-next
      # msty
      # mission-center
      # jujutsu
      # planify
      todoist
      unstable.beeper
      flakes.devenv.packages.${pkgs.system}.devenv

      # Install desktop apps rather than websites
      # discord
      feishin
      handy
      gh

      vlc
      evince
      kdePackages.gwenview
      nemo-with-extensions
      file-roller
      anki
      calibre

      # Work
      slack
      awscli2
      imhex

      # Language servers
      taplo
      nil
      nixd
    ];
    programs = {
      low-battery-alert.enable = true;
      granted.enable = true;
      alacritty.enable = true;
      waybar.enable = true;
      nixvim.enable = true;
      claude.enable = true;
      screen-journal = {
        enable = true;
        video = {
          enable = true;
          fps = 5;
        };
      };

      gitui.enable = true;
      firefox.enable = false;
      zen-browser.enable = true;

      webapps = {
        twenty.enable = true;
        lobe-chat.enable = true;
        hackernews.enable = true;
      };

      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-vaapi
          obs-vkcapture
          obs-gstreamer
          obs-pipewire-audio-capture
        ];
      };
    };

    services = {
      activitywatch.enable = true;
      dunst.enable = true;
      gpg-agent.enable = true;
      vicinae = {
        enable = true;
        autoStart = true;
      };
    };

    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://vicinae.cachix.org"
        "https://install.determinate.systems"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      ];
    };
  };

  environment.systemPackages = [
    config.boot.kernelPackages.perf
  ];

  programs.noisetorch = {
    enable = true;
    package = pkgs.noisetorch;
  };

  programs = {
    fcitx5.enable = true;
    nix-ld.enable = true;
    nix-index.enable = true;
    oneleet = {
      enable = true;
      service.enable = true;
    };
    pay-respects.enable = true;
  };

  services = {
    flatpak.enable = true;
    multi-scrobbler.enable = true;
    restic = {
      enable = true;
      paths = [
        "/home/${user}/Documents"
        "/home/${user}/Pictures"
        "/home/${user}/Desktop"

        "/home/${user}/.ssh"
        "/home/${user}/.gnupg"
        "/home/${user}/.local/share/atuin"
        "/home/${user}/.local/share/activitywatch"
      ];
      excludes = [];
      localBackup = {
        paths = [
          "/home/${user}/Videos/obs"
          "/home/${user}/Videos/Music"
        ];
        enable = true;
        schedule = "daily";
      };
      remoteBackup = {
        enable = true;
        repository = "s3:s3.eu-central-003.backblazeb2.com/framework-cf912bac41384519";
        schedule = "daily";
      };
    };
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
    safeeyes.enable = false;
    navidrome = {
      enable = true;
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
    };
    yubikey.enable = true;
    systembus-notify.enable = lib.mkForce true;
  };

  hardware = {
    powersave.enable = true;
    bluetooth.enable = true;
    sound.enable = true;
    ssd.enable = true;
    fingerprint.enable = true;
    fw-fanctrl.enable = true;
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
  stylix.enable = true;

  age.identityPaths = ["/home/${user}/.ssh/id_rsa"];

  networking = {
    hostName = "framework";
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
