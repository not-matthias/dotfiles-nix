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
      tdesktop
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
      gwenview
      weektodo

      # Dev
      jetbrains-mono
      jetbrains.clion
      jetbrains-fleet
      graphviz
      cmake
      gitAndTools.gh
      python310
      devenv
      bless
      wineWowPackages.stable # 32-bit and 64-bit
      winetricks

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
