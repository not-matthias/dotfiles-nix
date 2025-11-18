{...}: {
  nixpkgs.overlays = [
    (_self: super: {
      binary-ninja = super.callPackage ../../pkgs/binary-ninja.nix {};
    })
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
      feishin = super.callPackage ../../pkgs/feishin.nix {};
    })
    (_self: super: {
      handy = super.callPackage ../../pkgs/handy.nix {};
    })
    (_self: super: {
      solidtime-desktop = super.callPackage ../../pkgs/solidtime.nix {};
    })
    (_self: super: {
      zessionizer = super.callPackage ../../pkgs/zessionizer.nix {inherit (super) fenix;};
    })
    (_self: super: {
      antigravity = super.callPackage ../../pkgs/antigravity.nix {};
    })
    # (_self: super: {
    #   lobe-chat = super.callPackage ../../pkgs/lobe-chat.nix {};
    # })
  ];
}
