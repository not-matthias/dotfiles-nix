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
      package = pkgs.bluez-experimental;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          KernelExperimental = true;
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
