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
      # Tools
      bat
      eza
      bottom
      tokei
      alejandra
      zoxide
      fcp
      tealdeer
      treefmt
      fzf
      kalker
      ripgrep
      du-dust
      topgrade
      hexyl
      fd
      gping
      delta # TODO: Set as git default
      any-nix-shell
      duf
      wl-clipboard
      # Others:
      # ouch
      # kooha
      # hyperfine
      # oxipng

      # User
      #signal-desktop
      #anki
      #calibre
      vlc
      evince
      gwenview
      gnome.nautilus
      gnome.file-roller
      gnome-text-editor
      # zotero
      # obs-studio
      # xournalpp
      # libreoffice
      # amberol
      # syncthing
      # exodus

      # Dev
      unstable.zed-editor
      jetbrains-mono
      graphviz
      gitAndTools.gh
      python3
      devenv
      #bless
      #wineWowPackages.stable # 32-bit and 64-bit
      #winetricks

      # Useful tools
      unzip
      zip

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
