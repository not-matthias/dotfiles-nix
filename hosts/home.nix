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
      navi
      yazi
      eza
      bottom
      tealdeer
      kalker
      ripgrep
      du-dust
      topgrade
      hexyl
      fd
      delta
      any-nix-shell
      duf
      wl-clipboard

      # Useful tools
      python3

      # Productivity
      calcurse
      khal

      # Others:
      gping
      ouch
      # kooha
      # hyperfine
      # oxipng
      fzf
      # tokei
      procs
      # alejandra
      # treefmt

      bun

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
  };

  programs = {
    home-manager.enable = true;
    nh = {
      enable = true;
      clean.enable = true;
    };
    claude.enable = true;
  };
}
