{pkgs, ...}: {
  nixpkgs.overlays = [
    # This overlay will pull the latest version of Discord
    (_self: super: {
      discord = super.discord.overrideAttrs (
        _: {
          src = builtins.fetchTarball {
            url = "https://discord.com/api/download?platform=linux&format=tar.gz";
            sha256 = "sha256:087p8z538cyfa9phd4nvzjrvx4s9952jz1azb2k8g6pggh1vxwm8";
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
