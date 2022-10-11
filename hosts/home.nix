{
  nixpkgs,
  config,
  pkgs,
  lib,
  user,
  ...
}: {
  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    stateVersion = "22.05";
  }

  programs = {
    home-manager.enable = true;
  };

  # nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnfreePredicate = pkg:
  #   builtins.elem (lib.getName pkg) [
  #     "vscode"
  #     "clion"
  #     "obsidian"
  #     "discord"
  #   ];

  # home.sessionVariables = {
  #   EDITOR = "nvim";
  #   BROWSER = "firefox";
  #   TERMINAL = "alacritty";
  # };

  # pam.sessionVariables =
  #   config.home.sessionVariables
  #   // {
  #     LANGUAGE = "en_US:en";
  #     LANG = "en_US.UTF-8";
  #   };

  # # TODO: https://github.com/yrashk/nix-home/blob/master/home.nix#L65
  # home.packages = with pkgs; [
  #   fish

  #   # Tools
  #   bat
  #   exa
  #   bottom
  #   btop
  #   tokei
  #   alejandra
  #   zoxide
  #   mcfly
  #   fcp
  #   tealdeer
  #   treefmt
  #   fzf
  #   kalker
  #   ripgrep
  #   du-dust
  #   topgrade
  #   hyperfine
  #   hexyl
  #   fd
  #   gping
  #   ouch
  #   oxipng
  #   delta # TODO: Set as git default

  #   # Cargo tools
  #   cargo-edit
  #   cargo-expand
  #   cargo-udeps
  #   cargo-update
  #   cargo-sort
  #   cargo-criterion
  #   cargo-asm
  #   #    cargo-aoc
  #   cargo-bloat

  #   # User
  #   signal-desktop
  #   discord
  #   betterdiscordctl
  #   obsidian
  #   anki
  #   xournalpp
  #   calibre
  #   vlc
  #   krita
  #   obs-studio
  #   cava
  #   notepadqq
  #   flameshot
  #   zotero

  #   # Dev
  #   jetbrains-mono
  #   #    jetbrains.clion
  #   wine
  #   docker
  #   docker-compose
  #   virt-manager
  #   qemu_kvm
  #   graphviz
  #   cmake
  #   gitAndTools.gh

  #   # Misc
  #   papirus-icon-theme
  #   gnome.adwaita-icon-theme
  #   gnome.gnome-tweaks
  # ];

  # # Ensure fonts installed via Nix are picked up.
  # fonts.fontconfig.enable = true;

  # imports = (import ./programs) ++ (import ./services);
}
