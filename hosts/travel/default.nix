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

      nautilus
      file-roller
      gnome-text-editor
      slack

      awscli2
      flakes.zen-browser.packages."${system}".default

      # Language servers
      taplo
      nil
      nixd
    ];
    programs = {
      granted.enable = true;
      kitty.enable = true;
      alacritty.enable = true;
      waybar.enable = true;
      nixvim.enable = true;

      gitui.enable = true;
    };

    services = {
      dunst.enable = true;
      gpg-agent.enable = true;
    };
  };

  programs = {
    nix-ld.enable = true;
  };

  services = {
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
    docker.enable = true;
  };
  desktop = {
    hyprland.enable = true;
    fonts.enable = true;
  };

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
  };

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 1;
    };
    efi.canTouchEfiVariables = true;
  };
}
