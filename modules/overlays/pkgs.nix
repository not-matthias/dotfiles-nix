{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy/default.nix {};
    })
  ];
}
