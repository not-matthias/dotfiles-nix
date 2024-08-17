{
  config,
  pkgs,
  flakes,
  user,
  lib,
  ...
}: {
  imports = (import ../modules/overlays) ++ (import ../modules/system);

  boot = {
    supportedFilesystems = ["ntfs"];

    # Disable security mitigations. Don't use this on servers/multi-user systems.
    kernelParams = ["mitigations=off"];

    tmp.cleanOnBoot = lib.mkDefault true;
  };

  users.defaultUserShell = pkgs.fish;
  users.users.${user} = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = ["wheel" "video" "audio" "camera" "networkmanager" "kvm" "libvirtd"];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "Europe/Vienna";
  i18n = {
    defaultLocale = "en_US.utf8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment = {
    variables = {
      TERMINAL = "alacritty";
      BROWSER = "firefox";
      EDITOR = "nvim";
      VISUAL = "nvim";
      NIXPKGS_ALLOW_UNFREE = "1";
    };
    systemPackages = with pkgs; [
      nano
      vim
      wget
      pciutils
      usbutils
    ];
  };

  # Use system76-scheduler instead of default one
  services.system76-scheduler.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix = {
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry.nixpkgs.flake = flakes.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
    '';
  };
  system = {
    autoUpgrade = {
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
    stateVersion = "23.11";
  };

  # Cachix
  nix.settings = {
    trusted-users = ["root" "${user}"];
    substituters = [
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
