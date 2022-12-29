{
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.pkgSets.${pkgs.system};
in {
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.BurntSienna;
    enabledCustomApps = with spicePkgs.apps; [
      new-releases
      reddit
      marketplace
    ];
    enabledExtensions = with spicePkgs.extensions; [
      keyboardShortcut
      history
      fullAppDisplay
      shuffle
      hidePodcasts
      songStats
      autoVolume
      history
      genre
      adblock
    ];
  };
}
