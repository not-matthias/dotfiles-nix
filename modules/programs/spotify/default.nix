{
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.pkgSets.${pkgs.system};
in {
  programs.spicetify = {
    enable = true;
    theme = "BurntSienna";
    enabledCustomApps = with spicePkgs.apps; [
      new-releases
      reddit
      marketplace
    ];
    enabledExtensions = [
      "keyboardShortcut.js"
      "fullAppDisplay.js"
      "shuffle+.js"
      "hidePodcasts.js"
      "songStats.js"
      "autoVolume.js"
      "history.js"
      "genre.js"
      "adblock.js"
    ];
  };
}
