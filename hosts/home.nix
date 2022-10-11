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

    packages = with pkgs; [
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
      calibre
      vlc
      krita
      obs-studio
      cava
      notepadqq
      flameshot
      zotero

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
      gitAndTools.gh

      # Misc
      papirus-icon-theme
      gnome.adwaita-icon-theme
      gnome.gnome-tweaks
    ];

    stateVersion = "22.05";
  };

  programs = {
    home-manager.enable = true;
  };

  imports = (import ../modules/programs) ++ (import ../modules/services);
}
