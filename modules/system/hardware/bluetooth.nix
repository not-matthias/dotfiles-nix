{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hardware.bluetooth;
in {
  config = lib.mkIf cfg.enable {
    services.blueman.enable = true;

    hardware.bluetooth = {
      package =
        if pkgs.bluez.version == "5.86"
        then
          pkgs.bluez.overrideAttrs (old: {
            patches =
              (old.patches or [])
              ++ [
                (pkgs.fetchpatch {
                  url = "https://github.com/bluez/bluez/commit/066a164a524e4983b850f5659b921cb42f84a0e0.patch";
                  hash = "sha256-iitdib8VxPWaBUXrxAJ4/YHdBUDMGiDDSEBK+c4aPoE=";
                })
              ];
          })
        else pkgs.bluez;
      settings = {
        General = {
          # When enabled other devices can connect faster to us, however
          # the tradeoff is increased power consumption. Defaults to
          FastConnectable = true;
        };
        Policy = {
          # Enable all controllers when they are found. This includes
          # adapters present on start as well as adapters that are plugged
          # in later on. Defaults to 'true'.
          AutoEnable = false;
        };
        LE = {
          EnableAdvMonInterleave = true;
        };
      };
    };
  };
}
