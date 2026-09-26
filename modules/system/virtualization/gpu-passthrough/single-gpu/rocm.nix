{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.single-gpu-passthrough.amd;
in {
  options.virtualisation.single-gpu-passthrough.amd = {
    enable = lib.mkEnableOption "AMD single-GPU passthrough";
    guest = lib.mkOption {
      type = lib.types.str;
      default = "win11";
      description = "The libvirt guest that receives the GPU.";
    };
    devices = lib.mkOption {
      type = lib.types.nonEmptyListOf (lib.types.strMatching "[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\\.[0-7]");
      default = ["0000:c2:00.0" "0000:c2:00.1"];
      description = "PCI addresses of all devices in the GPU's IOMMU group.";
    };
    services = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["display-manager.service"];
      example = ["display-manager.service" "ollama.service"];
      description = "GPU-using services to stop before detaching and restart after reattaching. ROCm users outside listed services (such as LM Studio or background compute jobs) must exit before handoff.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.libvirtd.enable;
        message = "AMD single-GPU passthrough requires virtualisation.libvirtd.enable";
      }
      {
        assertion = !config.virtualisation.single-gpu-passthrough.nvidia.enable;
        message = "Enable only one of NVIDIA or AMD single-GPU passthrough";
      }
      {
        assertion = !(builtins.elem "amd_iommu=off" config.boot.kernelParams);
        message = "Remove amd_iommu=off from boot.kernelParams before enabling AMD single-GPU passthrough";
      }
    ];
    virtualisation.qemu.enable = true;
    boot.kernelParams = ["amd_iommu=on" "iommu=pt"];
    # The hook owns detach/reattach; the guest's hostdev entries need managed='no'.
    virtualisation.libvirtd.hooks.qemu.single-gpu-amd = import ./hook.nix {
      inherit pkgs lib;
      inherit (cfg) guest devices services;
      kernelModules = ["amdgpu"];
    };
  };
}
