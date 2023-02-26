{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      bytecode-viewer = super.callPackage ../../pkgs/bytecode-viewer/default.nix {};
    })
    (_self: super: {
      idafree = super.libsForQt5.callPackage ../../pkgs/idafree/default.nix {};
    })
    (_self: super: {
      idea-copilot = super.callPackage ../../pkgs/idea-copilot/default.nix {};
    })
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy/default.nix {};
    })
    (_self: super: {
      jetbrains-fleet = super.callPackage ../../pkgs/jetbrains-fleet/default.nix {};
    })
    (_self: super: {
      workrave-qt = super.libsForQt5.callPackage ../../pkgs/workrave-qt/default.nix {};
    })
    (_self: super: {
      recaf = super.callPackage ../../pkgs/recaf/default.nix {};
    })
  ];
}
