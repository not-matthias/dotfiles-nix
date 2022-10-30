{...}: {
  imports =
    [(import ../../modules/desktop/gnome/dconf.nix)];
    # ++ [(import ../../modules/desktop/i3/home.nix)]
 #   ++ [(import ../../modules/desktop/sway/home.nix)];
}
