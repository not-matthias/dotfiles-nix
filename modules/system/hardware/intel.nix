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
    boot = {
      # enable_psr: prevents screen flickering
      # enable_dc: disable gpu power management to prevent freezes
      extraModprobeConfig = ''
        options i915 enable_guc=3 enable_fbc=1 enable_dc=0 enable_psr=0
      '';
      initrd.kernelModules = ["i915"];
    };

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        #(vaapiIntel.override {enableHybridCodec = true;})
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [vaapiIntel];

    # services.xserver.videoDrivers = ["intel"];
  };
}
