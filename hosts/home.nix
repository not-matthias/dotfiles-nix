{
  pkgs,
  unstable,
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
      unstable.claude-code

      # Others:
      # gping
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
  };

  programs = {
    home-manager.enable = true;
  };
}
