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
      # enable_guc: Enable GuC / HuC firmware loading (3 = Alder Lake-P (Mobile) and newer)
      # enable_psr: prevents screen flickering
      # enable_dc: disable gpu power management to prevent freezes
      # enable_fbc: Framebuffer compression to reduce power consumption
      extraModprobeConfig = ''
        options i915 enable_guc=3 enable_fbc=1 enable_dc=0 enable_psr=0  enable_rc6=1
      '';
      initrd.kernelModules = ["i915"];
    };

    nixpkgs.config.packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    };

    # TODO: Merge this with nixos-hardware

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        # intel-media-driver
        # (vaapiIntel.override {enableHybridCodec = true;})
        # vaapiIntel
        # vaapiVdpau
        # libvdpau-va-gl
      ];
      # extraPackages32 = with pkgs.pkgsi686Linux; [vaapiIntel];
    };

    # services.xserver.videoDrivers = ["intel"];

    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
