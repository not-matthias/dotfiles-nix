{
  pkgs,
  unstable,
  user,
  flakes,
  lib,
  nixos-hardware,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
  ];
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  home-manager.users.${user} = {config, lib, ...}: {
    imports = [
      flakes.backhub.homeManagerModules.default
    ];
    home.stateVersion = "26.05";
    home.packages = with pkgs; [
      evince
      kdePackages.gwenview
      file-roller
      ida-pro
      unstable.amdtop
    ];
    backhub = {
      enable = true;
      # Provisioned outside this flake; contains only the raw GitHub token.
      secretFile = "/run/secrets/backhub-github-token";
      settings = {
        root = "${config.home.homeDirectory}/backups/backhub";
        source = {
          own = true;
          fork = true;
          star = true;
          gist = true;
          followers = true;
        };
      };
    };

    programs = {
      lmstudio = {
        enable = true;
        rocm.enable = true;
      };
      git.settings.commit.gpgsign = lib.mkForce false;
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
      vscode.enable = true;
      binary-ninja = {
        enable = true;
        extensions = [
          pkgs.binja-wasm
          pkgs.binja-headless
          pkgs.binja-codemode-mcp
        ];
      };
      cli-agents = {
        claude.enable = true;
        herdr = {
          enable = true;
        };
        oh-my-pi = {
          enable = true;
          envFile = "/run/agenix/pi-mono-env";
        };
      };
      btop.enable = true;
      worktrunk.enable = true;
      helium.enable = true;
      minecraft.enable = true;
      discord = {
        enable = true;
        package = pkgs.discord.override {
          withVencord = true;
          withOpenASAR = true;
        };
      };
    };

    services = {
      activitywatch.enable = true;
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
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libevdev
        libdrm
        elfutils.out
        zlib
        zstd
        stdenv.cc.cc.lib
      ];
    };
    sccache.enable = true;
    nix-index.enable = true;
    pay-respects.enable = true;
  };

  services = {
    kaneo = {
      enable = true;
      publicUrl = "http://pc.ide-snares.ts.net:5173";
    };
    tuned = {
      enable = true;
      settings.dynamic_tuning = true;
      ppdSettings = {
        main.default = "performance";
        profiles = {
          power-saver = "powersave";
          balanced = "balanced";
          performance = "throughput-performance";
        };
      };
    };
    restic.enable = false; # agenix disabled on pc; re-enable once secrets work again
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
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };
  users.users.${user}.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDvED6PbgTV9/yjDymEci/ATe6vQDb9c11hqUwNyEStvFmkDr5ili7+2fiUhTrNaefTX5RaDIRaKBu4jl+kjSn5tfv+lvdYbl/UM8yMN8YODcM4JbAUo5cyX76s5BXaBrqQH0TGEXhKlLkVdxCJCBLm9tpakkxgLruj0qEwSoSGruM/QCYgbhXrh9NcEtOBaOBZ39DUhT3MEKgZJBlbqIXqyeHN5L1GLBEgBN73dZhh7fsJdIpfaezqzIeu8FQnAnL94eOFlDx7PXm1Wiacpcb5S7GsIFnd1iEc/TlYyaXKN+12VK2qPe6KMZfF7lBvgnjEU868sHiU8OXpWkYWQ3RJs0uQqSylQum8jsJAOWcygavVRrOO+zDxzNkPXa+7H3Jah9XoywaKjz8rsPTs0qu/AWZG/KyV7EeQu+J6oIOXGv2OBcndRuQTBKIimHCdnGEnpgkAzw9gs14oc0MN97k1izb5zyK6zf4jsD8cHl+64Hevapto28yqcCanQk9p9+M= not-matthias@laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2yZENvNlZ8XQxcPVG8CrSEaUmvthPwheHRruEKqnzP not-matthias@raspi"
  ];

  virtualisation.podman.enable = true;
  desktop = {
    theme = "dark";
    niri.enable = true;
    fonts.enable = true;
  };

  age.identityPaths = [];
  age.secrets = lib.mkForce {}; # no ssh identity on pc for agenix; restic disabled above until this is resolved

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
      radius2
