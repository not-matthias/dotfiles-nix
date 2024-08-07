{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy/default.nix {};
    })
    (_self: super: {
      msty = super.callPackage ../../pkgs/msty.nix {};
    })
  ];
}
