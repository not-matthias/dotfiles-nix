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
    nh = {
      enable = true;
      clean.enable = true;
    };
    claude.enable = true;
  };

  # TODO: Make this configurable? Maybe move to program/service?
  stylix = {
    enable = true;
    autoEnable = true;

    base16Scheme = {
      base00 = "eff1f5";
      base01 = "e6e9ef";
      base02 = "ccd0da";
      base03 = "bcc0cc";
      base04 = "acb0be";
      base05 = "4c4f69";
      base06 = "d20f39";
      base07 = "d20f39";
      base08 = "d20f39";
      base09 = "fe640b";
      base0A = "df8e1d";
      base0B = "40a02b";
      base0C = "179299";
      base0D = "d20f39";
      base0E = "d20f39";
      base0F = "d20f39";
    };
    targets = {
      gtk.enable = false;
    };

    image = ../modules/system/desktop/hyprland/home/wallpaper.png;

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      light = "Papirus";
      dark = "Papirus-Dark";
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    fonts = {
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.ibm-plex;
        name = "IBM Plex Serif";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        desktop = 12;
        popups = 10;
        terminal = 12;
      };
    };
  };
}
