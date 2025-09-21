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
    environment.systemPackages = [
      pkgs.fprintd
    ];

    # https://discourse.nixos.org/t/fprintd-on-t440p/1350/3
    services.fprintd.enable = true;
    # start the driver at boot
    systemd.services.fprintd = {
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "simple";
    };

    security.pam.services = {
      login.fprintAuth = lib.mkForce true;
      xscreensaver.fprintAuth = true;
      sudo.fprintAuth = true;
      polkit-1.fprintAuth = true;
      swaylock.fprintAuth = true;
    };
  };
}
