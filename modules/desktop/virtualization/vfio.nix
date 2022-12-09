# References:
# - https://discourse.nixos.org/t/gpu-passthrough-shows-black-screen/17435
# - https://gist.github.com/CRTified/43b7ce84cd238673f7f24652c85980b3
# - https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html 
# - https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.virtualisation.vfio;
in {
  options.virtualisation.vfio = {
    enable = mkEnableOption "VFIO Configuration";
    IOMMUType = mkOption {
      type = types.enum ["intel" "amd"];
      example = "intel";
      description = "Type of the IOMMU used.";
    };
    devices = mkOption {
      type = types.listOf (types.strMatching "[0-9a-f]{4}:[0-9a-f]{4}");
      default = [];
      example = ["10de:1b80" "10de:10f0"];
      description = "PCI IDs of devices to bind to vfio-pci.";
    };
    blacklistNvidia = mkOption {
      type = types.bool;
      default = false;
      description = "Add Nvidia GPU modules to blacklist.";
    };
    blacklistAMD = mkOption {
      type = types.bool;
      default = false;
      description = "Add AMD GPU modules to blacklist.";
    };
    ignoreMSRs = mkOption {
      type = types.bool;
      default = false;
      description = "Enables or disables kvm guest access to model-specific registers.";
    };
    enableNestedVirt = mkOption {
      type = types.bool;
      default = false;
      description = "Enables nested virtualization.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelParams =
      (
        if cfg.IOMMUType == "intel"
        then [
          "intel_iommu=on"
          "intel_iommu=igfx_off"
        ]
        else ["amd_iommu=on"]
      )
      ++ (optional (builtins.length cfg.devices > 0)
        ("vfio-pci.ids=" + builtins.concatStringsSep "," cfg.devices))
      ++ (optional cfg.ignoreMSRs "kvm.ignore_msrs=1");

    boot.extraModprobeConfig =
      if cfg.enableNestedVirt
      then "options kvm_${cfg.IOMMUType} nested=1"
      else "";

    boot.blacklistedKernelModules =
      (optionals cfg.blacklistNvidia ["nvidia" "nouveau"])
      ++ (optionals cfg.blacklistAMD ["amdgpu" "radeon"]);

    boot.kernelModules = ["vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio"];
    boot.initrd.kernelModules = ["vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio"];
  };
}
