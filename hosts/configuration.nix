{
  config,
  lib,
  pkgs,
  inputs,
  user,
  location,
  ...
}: {
  users.users.${user} = {
    isNormalUser = true;
    extraGroups = ["wheel" "video" "audio" "camera" "networkmanager" "kvm" "libvirtd"];
    shell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "Europe/Vienna";
  i18n = {
    defaultLocale = "en_US.utf8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_AT.utf8";
      LC_IDENTIFICATION = "de_AT.utf8";
      LC_MEASUREMENT = "de_AT.utf8";
      LC_MONETARY = "de_AT.utf8";
      LC_NAME = "de_AT.utf8";
      LC_NUMERIC = "de_AT.utf8";
      LC_PAPER = "de_AT.utf8";
      LC_TELEPHONE = "de_AT.utf8";
      LC_TIME = "de_AT.utf8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  fonts.fonts = with pkgs; [
    # Fonts
    carlito # NixOS
    vegur # NixOS
    source-code-pro
    jetbrains-mono
    font-awesome # Icons
    corefonts # MS
    (nerdfonts.override {
      # Nerdfont Icons override
      fonts = [
        "FiraCode"
      ];
    })
  ];

  environment = {
    variables = {
      TERMINAL = "alacritty";
      BROWSER = "firefox";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    systemPackages = with pkgs; [
      nano
      vim
      wget
      pciutils
      usbutils
    ];
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs          = true
      keep-derivations      = true
    '';
  };
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
      "clion"
      "obsidian"
      "discord"
    ];

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
    stateVersion = "22.05";
  };
}
