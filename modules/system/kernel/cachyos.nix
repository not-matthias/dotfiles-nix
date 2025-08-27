{
  lib,
  config,
  pkgs,
  chaotic,
  ...
}:
with lib; let
  cfg = config.kernel.cachyos;
in {
  imports = [
    chaotic.nixosModules.default
  ];

  options.kernel.cachyos = {
    enable = mkEnableOption "CachyOS kernel and scheduler";

    scheduler = mkOption {
      type = types.enum ["scx_rustland" "scx_rusty" "scx_bpfland" "default"];
      default = "scx_rustland";
      description = "Which sched-ext scheduler to use";
    };

    mArch = mkOption {
      type = types.enum ["GENERIC" "GENERIC_V2" "GENERIC_V3" "GENERIC_V4" "ZEN4"];
      default = "GENERIC_V3";
      description = "Microarchitecture optimization level";
    };
  };

  config = mkIf cfg.enable {
    # Enable the Chaotic-Nyx cache
    chaotic.nyx.cache.enable = true;

    # Configure CachyOS kernel
    boot.kernelPackages = mkForce (pkgs.linuxPackages_cachyos.cachyOverride {
      mArch = cfg.mArch;
    });

    # Enable sched-ext scheduler service
    services.scx = {
      enable = true;
      scheduler = cfg.scheduler;
    };
  };
}