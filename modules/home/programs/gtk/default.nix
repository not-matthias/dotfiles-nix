# https://github.com/slwst/dotfiles/blob/3bddfc490f09ed1b0b8db90bf31074eafc3906ed/home/slwst/modules/desktop/gtk.nix#L18
{pkgs, ...}: {
  gtk = {
    enable = true;

    # FIXME: Adding this breaks gnome-shell (no icons, text, bar, ...)
    # font = {
    #   name = "Poppins";
    #   package = pkgs.google-fonts-poppins;
    # };

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    # https://github.com/catppuccin/gtk
    theme = {
      name = "Catppuccin-Orange-Light-Compact";
      package = pkgs.catppuccin-gtk.override {
        size = "compact";
        variant = "frappe";
      };
    };

    # https://github.com/PapirusDevelopmentTeam/papirus-icon-theme
    cursorTheme = {
      package = pkgs.catppuccin-cursors.frappeDark;
      name = "Catppuccin-Frappe-Light-Cursors";
    };
  };
}
