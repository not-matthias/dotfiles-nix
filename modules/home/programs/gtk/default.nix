{pkgs, ...}: {
  gtk = {
    enable = false;

    font = {
      name = "Roboto";
      package = pkgs.roboto;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    theme = {
      name = "Catppuccin-Orange-Dark-Compact";
      package = pkgs.catppuccin-gtk.override {size = "compact";};
    };
  };
}
