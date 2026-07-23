{
  pkgs,
  flakes,
  user,
  lib,
  ...
}: {
  imports = (import ../modules/overlays) ++ (import ../modules/system);

  boot = {
    # Disable security mitigations. Don't use this on servers/multi-user systems.
    kernelParams = ["mitigations=off"];

    tmp.cleanOnBoot = lib.mkDefault true;
  };
  zramSwap.enable = true;

  # Logs hardware errors (MCEs, ECC, PCIe AER) so silent reboots from
  # uncorrectable errors leave a trail in `ras-mc-ctl --errors`.
  hardware.rasdaemon.enable = true;

  users = {
    # TODO: Enable this in the future
    # mutableUsers = false;
    defaultUserShell = pkgs.fish;
    users.${user} = {
      isNormalUser = true;
      description = "${user}";
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "camera"
        "networkmanager"
        "kvm"
        "libvirtd"
        "docker"
      ];
      shell = pkgs.fish;
    };
  };
  programs = {
    fish.enable = true;
    dconf.enable = true;
    command-not-found.enable = false;
  };
  security.sudo.wheelNeedsPassword = true;

  time.timeZone = "Europe/Vienna";
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  documentation.man = {
    enable = false;
    cache.enable = false;
    man-db.enable = false;
  };

  environment = {
    variables = {
      TERMINAL = "ghostty";
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
      flakes.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # Remove perl, rsync and strace
    defaultPackages = lib.mkForce [];
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-31.7.7"
      "electron-36.9.5"
      "electron-39.8.10"
      "minio-2025-10-15T17-29-55Z"
      "pnpm-9.15.9"
    ];
  };
  nix = {
    optimise = {
      automatic = true;
      dates = "weekly";
    };
    gc = {
      automatic = true;
      dates = "weekly";
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
      trusted-users = [
        "root"
        "${user}"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        # Determinate Nix edge cache — mirrors cache.flakehub.com content, signed
        # with the same flakehub keys, but serves without auth. The daemon's
        # substituters must include it directly (extra-trusted-substituters alone
        # is a pre-approval list, not an automatic query list).
        "https://install.determinate.systems"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
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
