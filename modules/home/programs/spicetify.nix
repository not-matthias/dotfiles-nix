{
  lib,
  flakes,
  stable ? null,
  ...
}: let
  isSupported = stable != null && stable.stdenv.hostPlatform.system == "x86_64-linux";
  spicePkgs =
    if isSupported
    then flakes.spicetify-nix.legacyPackages.${stable.stdenv.hostPlatform.system}
    else null;
in {
  imports = lib.optional isSupported flakes.spicetify-nix.homeManagerModules.default;

  config =
    if isSupported
    then {
      programs.spicetify = {
        enable = lib.mkDefault true;
        wayland = true;
        # theme = spicePkgs.themes.catppuccin;
        # colorScheme = "mocha";
        enabledExtensions = with spicePkgs.extensions; [
          adblockify
          hidePodcasts
          shuffle
        ];
      };
    }
    else {};
}
