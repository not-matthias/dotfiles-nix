{
  pkgs,
  unstable,
  user,
  lib,
  flakes,
  nixos-hardware,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
  ];

  home-manager.users.${user} = {...}: {
    home.stateVersion = "26.05";
    home.packages = with pkgs; [
      evince
      kdePackages.gwenview
      file-roller

      lmstudio
    ];

    programs = {
      ghostty.enable = true;
      rust = {
        enable = true;
        maintenance.enable = true;
      };
      niri-organize.enable = true;
      helix = {
        enable = true;
        compat.enable = true;
      };
      cli-agents = {
        claude.enable = true;
        herdr = {
          enable = true;
        };
        oh-my-pi = {
          enable = true;
          envFile = "/run/agenix/pi-mono-env";
          theme = {
            dark = "light";
            light = "light";
          };
          discoverNestedSkills = true;
        };
      };
      btop.enable = true;
      worktrunk.enable = true;
      helium.enable = true;
    };

    services = {
      activitywatch.enable = false;
      gpg-agent.enable = true;
    };

    # Client-only nix settings — these reach ~/.config/nix/nix.conf (via
    # home-manager), NOT the daemon's nix.custom.conf. For substituters
    # that must be queried during nixos-rebuild builds, add them to
    # hosts/configuration.nix nix.settings instead.
    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://install.determinate.systems"
        "https://helix.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };

  programs = {
    nix-ld.enable = true;
    nix-ld.libraries = [pkgs.libevdev];
    sccache.enable = true;
    nix-index.enable = true;
    pay-respects.enable = true;
  };

  services = {
    tuned = {
      enable = true;
      settings.dynamic_tuning = true;
      ppdSettings.main.default = "performance";
    };
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

        # Agent session transcripts (.jsonl only; raw data excluded below)
        "/home/${user}/.omp/agent/sessions"
        "/home/${user}/.claude/projects"
        "/home/${user}/.pi/agent/sessions"
      ];
      excludes = [
        # omp: advisor analysis logs + image artifacts (bash logs already excluded by *.log)
        "**/.omp/agent/sessions/**/__advisor*.jsonl"
        "**/.omp/agent/sessions/**/local"
        # claude: non-transcript sidecar files (*.json won't match *.jsonl)
        "**/.claude/projects/**/*.wakatime"
        "**/.claude/projects/**/*.json"
        "**/.claude/projects/**/*.txt"
        "**/.claude/projects/**/*.md"
        "**/.claude/projects/**/*.js"
        "**/.claude/projects/**/*.pdf"
      ];
      localBackup = {
        paths = [
          "/home/${user}/Videos/obs"
          "/home/${user}/Videos/Music"
        ];
        enable = true;
        schedule = "daily";
      };
      # remoteBackup = {
      #   enable = true;
      #   repository = "s3:s3.eu-central-003.backblazeb2.com/framework-cf912bac41384519";
      #   schedule = "daily";
      # };
    };
    navidrome = {
      enable = true;
      musicFolder = "/home/${user}/Music";
      scrobblerUrl = "http://desktop.local:42010/apis/listenbrainz/1/";
      settings.Plugins = {
        Enabled = true;
        AutoReload = true;
        LogLevel = "info";
      };
    };
    octo-fiesta.enable = true;
    systembus-notify.enable = lib.mkForce true;
  };

  hardware = {
    bluetooth.enable = true;
    sound.enable = true;
    ssd.enable = true;
  };

  virtualisation.podman.enable = true;
  desktop = {
    theme = "light";
    niri.enable = true;
    fonts.enable = true;
  };

  age.identityPaths = ["/home/${user}/.ssh/id_rsa"];

  networking = {
    hostName = "pc";
    networkmanager.enable = true;

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
