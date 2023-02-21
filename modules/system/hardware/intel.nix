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
    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    };
    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        mesa_drivers
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    services.xserver.videoDrivers = ["intel"];
  };
}
