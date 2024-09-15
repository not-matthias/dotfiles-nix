{
  lib,
  config,
  ...
}: let
  cfg = config.hardware.bluetooth;
in {
  config = lib.mkIf cfg.enable {
    services.blueman.enable = true;

    hardware.bluetooth = {
      # enable = true; # Will be set by the user
      # hsphfpd.enable = true; # HSP & HFP daemon
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
}
