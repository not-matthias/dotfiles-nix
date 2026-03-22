{
  pkgs,
  unstable,
  user,
  lib,
  flakes,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];
  home-manager.users.${user} = {
    home.stateVersion = "22.05";
    home.packages = with pkgs; [
      unstable.zed-editor
      unstable.vscode
      bun
      nodejs
      google-chrome
      notepad-next
      # msty
      # mission-center
      # jujutsu
      # planify
      unstable.todoist # Requires v0.23+
      unstable.beeper
      flakes.devenv.packages.${pkgs.system}.devenv
      jetbrains.idea

      binary-ninja
      vmprotect
      ida-pro
      # unstable.antigravity-fhs

      # Install desktop apps rather than websites
      # discord
      feishin
      gh

      protonmail-bridge-gui
      thunderbird

      vlc
      evince
      kdePackages.gwenview
      file-roller
      anki
      calibre

      # Work
      slack
      awscli2
      imhex
      unstable.obsidian

      # Language servers
      taplo
      nil
      nixd
    ];
    programs = {
      ai-commit = {
        enable = true;
        provider = "claude";
      };
      ai-commit-all.enable = true;
      handy.enable = true;
      rust.enable = true;
      low-battery-alert.enable = true;
      niri-organize.enable = true;
      granted.enable = true;
      nixvim.enable = true;
      cli-agents = {
        agent-browser.enable = true;
        claude.enable = true;
        codex.enable = true;
        amp.enable = true;
        pi-mono.enable = true;
      };
      btop.enable = true;
      obsidian = {
        vault-links.personal = {
          vaultName = "personal-vault-v2";
          desktopName = "Obsidian - Personal Vault";
        };
      };
      ghidra = {
        enable = true;
        extensions = [
          "findcrypt"
          "lightkeeper"
          "wasm"
          "machinelearning"
          "sleighdevtools"
        ];
      };
      screenshot-journal.enable = false;

      gitui.enable = true;
      firefox.enable = false;
      zen-browser.enable = true;
      # waystt = {
      #   enable = true;
      #   provider = "local";
      #   whisperModel = "ggml-base.en.bin";
      #   enableAudioFeedback = true;
      # };

      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-vaapi
          obs-vkcapture
          obs-gstreamer
          obs-pipewire-audio-capture
        ];
      };
      solidtime-desktop.enable = true;
    };

    services = {
      ollama.enable = true;
      activitywatch.enable = false;
      gpg-agent.enable = true;
    };

    systemd.user.services.home-manager = {
      serviceConfig.TimeoutStartSec = "1min";
    };

    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://install.determinate.systems"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  };

  environment.systemPackages = [
    pkgs.perf
    pkgs.envfs
  ];

  # Disable Determinate Nix's built-in auto-GC (we use our own weekly nix-gc.timer)
  environment.etc."determinate/config.json".text = builtins.toJSON {
    garbageCollector.strategy = "disabled";
  };

  programs = {
    noisetorch.enable = true;
    steam.enable = true;
    fcitx5.enable = true;
    nix-ld.enable = true;
    nix-ld.libraries = [pkgs.libevdev];
    nix-index.enable = true;
    oneleet = {
      enable = true;
      service.enable = true;
    };
    pay-respects.enable = true;
  };

  services = {
    # solidtime.enable = true;
    vpn.enable = true;
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
    scx = {
      enable = true;
      scheduler = "scx_bpfland";
    };
    system76-scheduler = {
      enable = true;
      useStockConfig = false;
      settings = {
        cfsProfiles.enable = true;
        processScheduler = {
          enable = true;
          useExecsnoop = true;
          refreshInterval = 30;
          foregroundBoost = {
            enable = true;
            foreground = {
              nice = -2;
              ioClass = "best-effort";
              ioPrio = 0;
            };
            background = {
              nice = 8;
              ioClass = "best-effort";
              ioPrio = 4;
            };
          };
          pipewireBoost = {
            enable = true;
            profile = {
              nice = -10;
              ioClass = "best-effort";
              ioPrio = 0;
            };
          };
        };
      };
      assignments = {
        nix-builds = {
          nice = 15;
          class = "batch";
          ioClass = "idle";
          matchers = [
            "nix-daemon"
          ];
        };
        dev-tools = {
          class = "batch";
          matchers = [
            "rust-analyzer"
            "clangd"
            "nil"
            "nixd"
          ];
        };
        browsers = {
          nice = -2;
          ioClass = "best-effort";
          ioPrio = 0;
          matchers = ["firefox" "zen" "chromium"];
        };
        compositor = {
          nice = -5;
          ioClass = "best-effort";
          ioPrio = 0;
          matchers = ["niri"];
        };
      };
      exceptions = [
        "schedtool"
        "nice"
        "chrt"
        "ionice"
        "taskset"
        "rtkit-daemon"
      ];
    };
    safeeyes.enable = true;
    navidrome = {
      enable = true;
      musicFolder = "/home/${user}/Music";
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
      settings.Plugins = {
        Enabled = true;
        AutoReload = true;
        Folder = "/var/lib/navidrome/plugins";
        LogLevel = "info";
      };
    };
    audiomuse.enable = true;
    # soulsync.enable = true;
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
    niri.enable = true;
    fonts.enable = true;
  };

  age.identityPaths = ["/home/${user}/.ssh/id_rsa"];
  age.secrets = {};

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
