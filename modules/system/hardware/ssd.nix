{
  lib,
  config,
  ...
}: let
  cfg = config.custom.hardware.ssd;
in {
  options.custom.hardware.sdd = {
    enable = lib.mkEnableOption "SSD Configuration";
  };

  config = lib.mkIf cfg.enable {
    # https://wiki.archlinux.org/title/Solid_state_drive#TRIM
    # - SSDs benefit from informing the disk controller when blocks of memory are free to be reused
    services.fstrim.enable = true;
  };
}