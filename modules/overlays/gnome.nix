{pkgs, ...}: {
  # GNOME 46: triple-buffering-v4-46
  # See: https://nixos.wiki/wiki/GNOME
  nixpkgs.overlays = [
    (_: prev: {
      gnome = prev.gnome.overrideScope (_: gnomePrev: {
        mutter = gnomePrev.mutter.overrideAttrs (_: {
          src = pkgs.fetchgit {
            url = "https://gitlab.gnome.org/vanvugt/mutter.git";
            rev = "663f19bc02c1b4e3d1a67b4ad72d644f9b9d6970";
            sha256 = "sha256-I1s4yz5JEWJY65g+dgprchwZuPGP9djgYXrMMxDQGrs=";
          };
        });
      });
    })
  ];
}
