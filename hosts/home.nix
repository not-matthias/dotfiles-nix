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
      cargo-wipe

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

      # Dev
      jetbrains-mono
      jetbrains.idea-ultimate
      jetbrains.clion
      wine64
      graphviz
      cmake
      gitAndTools.gh
      python310
      conda

      # Currently not working:
      # devenv

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
