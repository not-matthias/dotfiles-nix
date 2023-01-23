{
  pkgs,
  user,
  ...
}: {
  imports = import ../modules/home ++ import ../modules/overlays;

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
      libreoffice

      # Dev
      jetbrains-mono
      idea-copilot
      jetbrains.clion
      # jetbrains.idea-ultimate
      #jetbrains.datagrip
      wine64
      graphviz
      cmake
      gitAndTools.gh
      python310
      conda

      # Reverse Engineering / CTF
      file
      gef
      gdb
      imhex
      idafree
      bytecode-viewer
      detect-it-easy
    ];

    stateVersion = "22.11";
  };

  programs = {
    home-manager.enable = true;
  };
}
