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
      evince
      libreoffice
      workrave-qt
      amberol

      # Dev
      jetbrains-mono
      jetbrains.clion
      jetbrains.idea-community
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
      binwalk
      gef
      gdb
      imhex
      detect-it-easy
      checksec
      idafree
      bytecode-viewer
      recaf
      dex2jar
      # jadx
      # avalonia-ilspy
    ];

    stateVersion = "22.11";
  };

  programs = {
    home-manager.enable = true;
  };
}
