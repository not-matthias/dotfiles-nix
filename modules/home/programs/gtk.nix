{
  config,
  pkgs,
  lib,
  ...
}: let
  stylixPolarity = config.stylix.polarity or "light";
  catppuccinVariant =
    if stylixPolarity == "dark"
    then "mocha"
    else "latte";
in {
  gtk = {
    enable = true;

    iconTheme = lib.mkDefault {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    # https://github.com/catppuccin/gtk
    theme = lib.mkForce {
      name = "catppuccin-${catppuccinVariant}-red-compact";
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = catppuccinVariant;
        accents = ["red" "blue"];
      };
    };
  };
}
