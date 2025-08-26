{
  pkgs,
  lib,
  ...
}: {
  gtk = {
    enable = true;

    # https://github.com/catppuccin/gtk
    theme = lib.mkForce {
      name = "catppuccin-latte-red-compact";
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "latte";
        accents = ["red" "blue"];
      };
    };
  };
}
