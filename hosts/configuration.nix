{
  pkgs,
  flakes,
  user,
  lib,
  config,
  ...
}: {
  imports = (import ../modules/overlays) ++ (import ../modules/system);

  boot = {
    # Disable security mitigations. Don't use this on servers/multi-user systems.
    kernelParams = ["mitigations=off"];

    tmp.cleanOnBoot = lib.mkDefault true;
  };

  users.defaultUserShell = pkgs.fish;
  users.users.${user} = {
    isNormalUser = true;
    description = "${user}";
    extraGroups = ["wheel" "video" "audio" "camera" "networkmanager" "kvm" "libvirtd" "docker"];
    shell = pkgs.fish;
  };
  programs.fish.enable = true;
  programs.dconf.enable = true;
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "Europe/Vienna";
  i18n = {
    defaultLocale = "en_US.UTF-8";
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
      usbutils
      flakes.agenix.packages.${system}.default
      config.boot.kernelPackages.perf
    ];

    # Remove perl, rsync and strace
    defaultPackages = lib.mkForce [];
  };

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
      keep-going            = true
    '';

    # Cachix
    settings = {
      trusted-users = ["root" "${user}"];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://walker.cachix.org"
        "https://walker-git.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];
    };
  };
  system = {
    autoUpgrade = {
      enable = false;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
    stateVersion = "23.11";
  };
}
