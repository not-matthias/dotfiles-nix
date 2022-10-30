{
  pkgs,
  user,
  ...
}: {
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

      # Cargo tools
      cargo-edit
      cargo-expand
      cargo-udeps
      cargo-update
      cargo-sort
      cargo-criterion
      cargo-asm
      #    cargo-aoc
      cargo-bloat

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
      notepadqq
      flameshot
      zotero
      evince
      libreoffice

      # Dev
      jetbrains-mono
      jetbrains.clion
      jetbrains.datagrip
      wine64
      graphviz
      cmake
      gitAndTools.gh
      python3

      # Misc
      papirus-icon-theme
      gnome.adwaita-icon-theme
      gnome.gnome-tweaks
      gnome.gnome-remote-desktop
      xdg-desktop-portal-gnome
      gnomeExtensions.paperwm
      gnomeExtensions.dash-to-dock
      gnomeExtensions.gnome-bedtime
    ];

    stateVersion = "22.05";
  };

  programs = {
    home-manager.enable = true;
  };

  imports = (import ../modules/programs) ++ (import ../modules/services);
}
