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
      hyperfine
      hexyl
      fd
      gping
      ouch
      oxipng
      delta # TODO: Set as git default
      any-nix-shell
      duf
      wl-clipboard
      kooha

      # User
      signal-desktop
      obsidian
      anki
      xournalpp
      calibre
      vlc
      obs-studio
      evince
      #libreoffice
      amberol
      gwenview
      syncthing
      #exodus
      gnome.file-roller
      gnome-text-editor
      termusic

      # Dev
      zed-editor
      jetbrains-mono
      jetbrains.rust-rover
      graphviz
      cmake
      gitAndTools.gh
      python3
      devenv
      bless
      wineWowPackages.stable # 32-bit and 64-bit
      winetricks

      # Useful tools
      unzip
      zip

      # Reverse Engineering / CTF
      file
      binwalk
      gef
      gdb
      imhex
      detect-it-easy
      checksec
      bytecode-viewer
      dex2jar
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
