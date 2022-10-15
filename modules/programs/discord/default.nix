{pkgs, ...}: {
  nixpkgs.overlays = [
    # This overlay will pull the latest version of Discord
    (self: super: {
      discord = super.discord.overrideAttrs (
        _: {
          src = builtins.fetchTarball {
            url = "https://discord.com/api/download?platform=linux&format=tar.gz";
            sha256 = "1kwqn1xr96kvrlbjd14m304g2finc5f5ljvnklg6fs5k4avrvmn4";
          };
        }
      );
    })
    # Allow opening links via firefox (https://github.com/NixOS/nixpkgs/issues/108995#issuecomment-826358042)
    (self: super: {
      discord = super.discord.override {
        nss = pkgs.nss_latest;
      };
    })
  ];
}
