{
  pkgs,
  user,
  ...
}: {
  imports = import ../modules/home;

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
      any-nix-shell
      duf

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
      evince
      libreoffice
      # elementary-planner

      # Dev
      jetbrains-mono
      jetbrains.clion
      jetbrains.datagrip
      wine64
      graphviz
      cmake
      gitAndTools.gh
      python310
      python310Packages.pip
      python310Packages.virtualenv
      conda

      # Reverse Engineering / CTF
      file
      gef
      gdb
    ];

    stateVersion = "22.05";
  };

  programs = {
    home-manager.enable = true;
  };
}
