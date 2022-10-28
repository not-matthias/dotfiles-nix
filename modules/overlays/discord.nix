{pkgs, ...}: {
  nixpkgs.overlays = [
    # This overlay will pull the latest version of Discord
    (_self: super: {
      discord = super.discord.overrideAttrs (
        _: {
          src = builtins.fetchTarball {
            url = "https://discord.com/api/download?platform=linux&format=tar.gz";
            sha256 = "1pw9q4290yn62xisbkc7a7ckb1sa5acp91plp2mfpg7gp7v60zvz";
          };
        }
      );
    })
    # Allow opening links via firefox (https://github.com/NixOS/nixpkgs/issues/108995#issuecomment-826358042)
    (_self: super: {
      discord = super.discord.override {
        nss = pkgs.nss_latest;
      };
    })
  ];
}
