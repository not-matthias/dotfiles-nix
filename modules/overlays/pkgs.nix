{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      bytecode-viewer = super.callPackage ../../pkgs/bytecode-viewer/default.nix {};
    })
    (_self: super: {
      idafree = super.libsForQt5.callPackage ../../pkgs/idafree/default.nix {};
    })
  ];
}
