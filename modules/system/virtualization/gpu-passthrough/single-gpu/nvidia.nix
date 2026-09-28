{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.single-gpu-passthrough.nvidia;
in {
  options.virtualisation.single-gpu-passthrough.nvidia = {
    enable = lib.mkEnableOption "NVIDIA single-GPU passthrough";
    guest = lib.mkOption {
      type = lib.types.str;
      default = "win10";
      description = "The libvirt guest that receives the GPU.";
    };
    devices = lib.mkOption {
      type = lib.types.nonEmptyListOf (lib.types.strMatching "[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\\.[0-7]");
      default = [
        "0000:26:00.0"
        "0000:26:00.1"
        "0000:26:00.2"
        "0000:26:00.3"
      ];
      description = "PCI addresses of every device in each IOMMU group being passed through.";
    };
    services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["display-manager.service"];
      example = ["display-manager.service" "ollama.service"];
      description = "GPU-using services to stop before detaching and restart after reattaching. Include the display manager and any NVIDIA compute services.";
    };
    cpuType = lib.mkOption {
      type = lib.types.enum ["amd" "intel"];
      default = "amd";
      example = "intel";
      description = "Host CPU architecture type ('amd' or 'intel') for IOMMU kernel parameters.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.virtualisation.single-gpu-passthrough.amd.enable;
        message = "Enable only one of the NVIDIA or AMD single-GPU passthrough hooks";
      }
    ];

    virtualisation.qemu.enable = true;

    boot.kernelParams =
      (
        if cfg.cpuType == "intel"
        then ["intel_iommu=on"]
        else ["amd_iommu=on"]
      )
      ++ ["iommu=pt"];

    # The hook owns detach/reattach; the guest's hostdev entries need managed='no'.
    virtualisation.libvirtd.hooks.qemu.single-gpu-nvidia = import ./hook.nix {
      inherit pkgs lib;
      inherit (cfg) guest devices services;
      kernelModules = ["nvidia_drm" "nvidia_uvm" "nvidia_modeset" "nvidia"];
    };
  };
}
