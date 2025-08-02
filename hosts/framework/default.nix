{
  pkgs,
  unstable,
  user,
  lib,
  ...
}: {
  imports = [(import ./hardware-configuration.nix)];
  home-manager.users.${user} = {
    home.stateVersion = "22.05";
    home.packages = with pkgs; [
      unstable.zed-editor
      unstable.supersonic
      unstable.vscode
      unstable.obsidian
      google-chrome
      unstable.lmstudio
      unstable.nodejs
      notepad-next
      unstable.opencode
      mission-center
      jujutsu
      unstable.beeper
      unstable.claude-code

      # Install desktop apps rather than websites
      discord
      todoist-electron
      unstable.feishin

      vlc
      evince
      kdePackages.gwenview
      nautilus
      file-roller
      gnome-text-editor
      unstable.anki
      calibre
      fastfetch

      # Work
      slack
      awscli2

      # Language servers
      taplo
      nil
      nixd
    ];
    programs = {
      low-battery-alert.enable = true;
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
      zen-browser.enable = true;

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
    sccache.enable = true;
    oneleet.enable = true;
  };

  # FIXME: Find a better way to configure this (only needed for MCP)
  environment.sessionVariables = {
    # Playwright configuration
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  services = {
    ntfy-sh.enable = true;
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
        ];
        enable = true;
        schedule = "daily";
      };
      remoteBackup = {
        enable = true;
        repository = "s3:s3.eu-central-003.backblazeb2.com/framework-cf912bac41384519";
        schedule = "weekly";
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
    earlyoom.enable = true;
    audiobookshelf = {
      enable = true;
      audioFolder = "/home/${user}/Audiobooks";
    };
    vpn.enable = true;
    safeeyes.enable = false;
    navidrome = {
      enable = true;
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
    };
    caddy.enable = true;
    yubikey.enable = true;
    smartd = {
      enable = true;
      autodetect = true;
      notifications.test = false;
      defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/03)";
    };
    systembus-notify.enable = lib.mkForce true;
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
