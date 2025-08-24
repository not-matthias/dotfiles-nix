{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      detect-it-easy = super.callPackage ../../pkgs/detect-it-easy.nix {};
    })
    (_self: super: {
      msty = super.callPackage ../../pkgs/msty.nix {};
    })
    # Just use the unstable version, which is almost always up-to-date and then we don't have to care about manually updating.
    # (_self: super: {
    #   claude-code = super.callPackage ../../pkgs/claude-code/default.nix {};
    # })
    (_self: super: {
      oneleet = super.callPackage ../../modules/system/programs/oneleet/default.nix {};
    })
    # (_self: super: {
    #   lobe-chat = super.callPackage ../../pkgs/lobe-chat.nix {};
    # })
  ];
}
