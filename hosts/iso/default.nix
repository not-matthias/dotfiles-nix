{
  pkgs,
  lib,
  user,
  unstable,
  flakes,
  modulesPath,
  ...
}: let
  defaultBrowser = {
    command = "helium";
    desktop = "helium.desktop";
  };
in {
  # Bootable live ISO base: provides the ISO bootloader, squashfs rootfs and
  # installer tooling. Replaces hardware-configuration.nix (no real-disk
  # fileSystems/luks/bootloader).
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  networking = {
    hostName = "iso";
    networkmanager.enable = true;
  };

  # Generic graphics + firmware so the live ISO lights up the display on the
  # Framework (AMD APU) and most other machines without hardware-configuration.
  hardware = {
    graphics.enable = true;
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    sound.enable = true;
  };

  # Live USB: no secrets on disk, no sudo password, known login password.
  security.sudo.wheelNeedsPassword = false;
  users.users.${user}.initialPassword = "nixos";

  # Autologin to the user on tty1, then drop straight into Niri via uwsm.
  # Niri has no display manager; fish is the login shell, so launch from
  # fish's loginShellInit (sourced on the tty1 autologin shell).
  services.getty.autologinUser = lib.mkForce user;
  programs.fish.loginShellInit = ''
    if test -z "$DISPLAY" -a (tty) = "/dev/tty1"
        if uwsm check may-start
            exec uwsm start niri
        end
    end
  '';

  # Faster squashfs compression than the default xz; good enough for a live USB.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # The shared Niri/stylix desktop stack (inherited from nixosBox modules).
  desktop = {
    niri.enable = true;
    fonts.enable = true;
  };

  home-manager.users.${user} = {...}: {
    home.stateVersion = "22.05";

    home.packages = with pkgs; [
      uv
      bun
      nodejs
      unstable.google-chrome
      unstable.todoist
      unstable.beeper
      flakes.devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv
      flakes.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk

      gh
      gh-dash

      vlc
      wdisplays
      evince
      kdePackages.gwenview
      file-roller
      anki
      imhex
      unstable.obsidian

      # Language servers
      taplo
      nil
      nixd
    ];

    xdg.mimeApps = {
      associations.added."text/html" = lib.mkForce defaultBrowser.desktop;
      defaultApplications = {
        "text/html" = lib.mkForce defaultBrowser.desktop;
        "x-scheme-handler/http" = lib.mkForce defaultBrowser.desktop;
        "x-scheme-handler/https" = lib.mkForce defaultBrowser.desktop;
      };
    };

    programs = {
      ghostty.enable = true;
      vscode.enable = true;
      gitui.enable = true;
      btop.enable = true;
      nixvim.enable = true;
      firefox.enable = false;
      zen-browser.enable = true;
      helium.enable = true;
      obsidian = {
        vault-links.personal = {
          vaultName = "personal-vault-v2";
          desktopName = "Obsidian - Personal Vault";
        };
      };
      discord = {
        enable = true;
        package = pkgs.discord.override {
          withVencord = true;
          withOpenASAR = true;
        };
      };
      ghidra.enable = false;
      screenshot-journal.enable = false;
    };

    services = {
      gpg-agent.enable = true;
      activitywatch.enable = false;
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
        "https://helix.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };
  };

  environment.variables.BROWSER = lib.mkForce defaultBrowser.command;
}
