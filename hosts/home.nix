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
      btop
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
      slack
      obsidian
      #anki # removed for now because it's not cached
      xournalpp
      calibre
      vlc
      obs-studio
      evince
      libreoffice
      amberol
      gwenview
      syncthing
      exodus
      gnome.file-roller
      gnome-text-editor

      # Dev
      jetbrains-mono
      jetbrains.rust-rover
      graphviz
      cmake
      gitAndTools.gh
      python310
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
      idafree
      bytecode-viewer
      dex2jar
      # recaf
      # binary-ninja
      # jadx
      # avalonia-ilspy
    ];

    stateVersion = "23.11";
  };

  programs = {
    home-manager.enable = true;
  };
}
