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
    defaultLocale = "en_US.utf8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment = {
    variables = {
      TERMINAL = "kitty";
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
    '';

    # Cachix
    settings = {
      trusted-users = ["root" "${user}"];
      substituters = [
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
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
