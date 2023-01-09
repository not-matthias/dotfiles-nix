{
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.packages.${pkgs.system}.default;
in {
  programs.spicetify = {
    enable = false;
    theme = spicePkgs.themes.BurntSienna;
    # enabledCustomApps = with spicePkgs.apps; [
    #   new-releases
    #   reddit
    #   marketplace
    # ];
    # enabledExtensions = with spicePkgs.extensions; [
    #   keyboardShortcut
    #   history
    #   fullAppDisplay
    #   shuffle
    #   hidePodcasts
    #   songStats
    #   autoVolume
    #   history
    #   genre
    #   adblock
    # ];
  };
}
