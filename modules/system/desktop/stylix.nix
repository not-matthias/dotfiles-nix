{
  config,
  lib,
  pkgs,
  ...
}: let
  palettes = import ./palettes.nix;
in {
  options.desktop.theme = lib.mkOption {
    type = lib.types.enum ["light" "dark"];
    default = "light";
    description = "Catppuccin Latte Red for light and Catppuccin Mocha Red for dark.";
  };

  config.stylix = {
    autoEnable = true;
    targets.gtk.enable = false;
    homeManagerIntegration.autoImport = true;
    homeManagerIntegration.followSystem = true;

    base16Scheme = palettes.${config.desktop.theme};

    polarity = config.desktop.theme;

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
        # package = pkgs.dejavu_fonts;
        # name = "DejaVu Sans";
        package = pkgs.atkinson-hyperlegible;
        name = "Atkinson Hyperlegible";
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
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 9;
        desktop = 9;
        popups = 9;
        terminal = 9;
      };
    };
  };
}
