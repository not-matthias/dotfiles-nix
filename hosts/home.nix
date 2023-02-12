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
      evince
      # libreoffice
      stretchly

      # Dev
      jetbrains-mono
      # jetbrains.idea-ultimate
      jetbrains.clion
      jetbrains-fleet
      wine64
      graphviz
      cmake
      gitAndTools.gh
      python310
      conda
      devenv

      # Reverse Engineering / CTF
      file
      gef
      gdb
      imhex
      idafree
      bytecode-viewer
      detect-it-easy
      checksec
    ];

    stateVersion = "22.11";
  };

  programs = {
    home-manager.enable = true;
  };
}
