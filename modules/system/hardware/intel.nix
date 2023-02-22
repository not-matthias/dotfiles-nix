{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.hardware.intel;
in {
  options.hardware.intel = {
    enable = lib.mkEnableOption "Intel Configuration";
  };

  config = lib.mkIf cfg.enable {
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [vaapiIntel];

    services.xserver.videoDrivers = ["intel"];
  };
}
