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
      # Rust tools
      bat
      eza
      bottom
      zoxide
      fcp
      tealdeer
      kalker
      ripgrep
      du-dust
      topgrade
      hexyl
      fd
      gping
      delta
      any-nix-shell
      duf
      wl-clipboard

      # Useful tools
      gitAndTools.gh
      unzip
      zip
      python3
      devenv

      # Others:
      # ouch
      # kooha
      # hyperfine
      # oxipng
      # fzf
      # tokei
      # alejandra
      # treefmt

      # User
      # anki
      # calibre
      # zotero
      # obs-studio
      # xournalpp
      # libreoffice
      # amberol
      # syncthing
      # exodus

      # Dev
      # graphviz
      # bless
      #
      # Reverse Engineering / CTF
      # file
      # binwalk
      # gef
      # gdb
      # imhex
      # detect-it-easy
      # checksec
      # bytecode-viewer
      # dex2jar
      # recaf
      # binary-ninja
      # jadx
      # avalonia-ilspy
    ];

    stateVersion = "24.05";
  };

  programs = {
    home-manager.enable = true;
  };
}
