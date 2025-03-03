{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.services.yubikey;
in {
  options.services.yubikey = {
    enable = lib.mkEnableOption "yubikey";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      yubioath-flutter
      yubikey-manager

      granted
    ];

    # Yubikey management
    services.udev.packages = [
      pkgs.yubikey-personalization
    ];
    services.pcscd.enable = true;
  };
}
