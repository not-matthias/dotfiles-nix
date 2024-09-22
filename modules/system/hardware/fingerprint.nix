# https://github.com/Kropatz/nix-config/blob/3bdb37559d2c912dc829ab240428a01b71802ff9/modules/hardware/fingerprint.nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.hardware.fingerprint;
in {
  options.hardware.fingerprint = {
    enable = lib.mkEnableOption "Enables fingerprint support";
  };

  config = lib.mkIf cfg.enable {
    services.fprintd = {
      enable = true;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-goodix;
      };
    };
  };
}
