{pkgs, ...}: {
  stylix = {
    autoEnable = true;
    targets.gtk.enable = false;
    homeManagerIntegration.autoImport = true;
    homeManagerIntegration.followSystem = true;

    base16Scheme = {
      base00 = "eff1f5"; # base
      base01 = "e6e9ef"; # mantle
      base02 = "ccd0da"; # surface0
      base03 = "bcc0cc"; # surface1
      base04 = "acb0be"; # surface2
      base05 = "4c4f69"; # text
      base06 = "d20f39"; # rosewater
      base07 = "d20f39"; # rosewater
      base08 = "d20f39"; # red
      base09 = "fe640b"; # peach
      base0A = "df8e1d"; # yellow
      base0B = "40a02b"; # green
      base0C = "179299"; # teal
      base0D = "d20f39"; # red (used for blue)
      base0E = "d20f39"; # red (used for mauve)
      base0F = "d20f39"; # red (used for pink)
    };

    polarity = "light";

    image = ./hyprland/home/wallpaper.png;

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
