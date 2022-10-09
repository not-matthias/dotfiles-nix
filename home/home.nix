{
  nixpkgs,
  config,
  pkgs,
  lib,
  ...
}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "not-matthias";
  home.homeDirectory = "/home/not-matthias";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "vscode"
      "clion"
      "obsidian"
      "discord"
    ];

  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
  };

  pam.sessionVariables =
    config.home.sessionVariables
    // {
      LANGUAGE = "en_US:en";
      LANG = "en_US.UTF-8";
    };

  # TODO: https://github.com/yrashk/nix-home/blob/master/home.nix#L65
  home.packages = with pkgs; [
    fish

    # Tools
    bat
    exa
    bottom
    btop
    tokei
    alejandra
    zoxide
    mcfly
    fcp
    tealdeer
    treefmt
    fzf
    kalker
    ripgrep
    du-dust
    topgrade
    hyperfine
    hexyl
    fd
    gping
    ouch
    oxipng
    delta # TODO: Set as git default

    # Cargo tools
    cargo-edit
    cargo-expand
    cargo-udeps
    cargo-update
    cargo-sort
    cargo-criterion
    cargo-asm
    #    cargo-aoc
    cargo-bloat

    # User
    signal-desktop
    discord
    betterdiscordctl
    obsidian
    anki
    xournalpp
    blanket
    calibre
    vlc
    krita
    obs-studio
    cava
    notepadqq
    flameshot

    # Dev
    jetbrains-mono
    #    jetbrains.clion
    wine
    docker
    docker-compose
    virt-manager
    qemu_kvm
    graphviz
    cmake

    # Misc
    papirus-icon-theme
    gnome.gnome-tweaks
  ];

  # Ensure fonts installed via Nix are picked up.
  fonts.fontconfig.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  imports = (import ./programs) ++ (import ./services);
}
