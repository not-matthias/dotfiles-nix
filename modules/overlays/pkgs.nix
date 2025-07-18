{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy.nix {};
    })
    (_self: super: {
      msty = super.callPackage ../../pkgs/msty.nix {};
    })
    (_self: super: {
      claude-code = super.callPackage ../../pkgs/claude-code/default.nix {};
    })
  ];
}
