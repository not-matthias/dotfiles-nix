# References:
# - https://discourse.nixos.org/t/gpu-passthrough-shows-black-screen/17435
# - https://gist.github.com/CRTified/43b7ce84cd238673f7f24652c85980b3
# - https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
# - https://astrid.tech/2022/09/22/0/nixos-gpu-vfio/
# - https://news.ycombinator.com/item?id=22897808
# - https://forum.level1techs.com/t/nixos-vfio-pcie-passthrough/130916
{
  lib,
  config,
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
    disableEFIfb = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Disables the usage of the EFI framebuffer on boot.";
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
    loadVfioPci = mkOption {
      type = types.bool;
      default = false;
      description = "Loads the vfio-pci module on boot.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;

    boot = {
      kernelParams =
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
        ++ (optional cfg.disableEFIfb "video=efifb:off")
        ++ (optionals cfg.ignoreMSRs [
          "kvm.ignore_msrs=1"
          "kvm.report_ignored_msrs=0"
        ]);

      extraModprobeConfig =
        if cfg.enableNestedVirt
        then "options kvm_${cfg.IOMMUType} nested=1"
        else "";

      blacklistedKernelModules =
        (optionals cfg.blacklistNvidia ["nvidia" "nouveau"])
        ++ (optionals cfg.blacklistAMD ["amdgpu" "radeon"]);

      # Load the vfio-pci module on boot
      kernelModules =
        if cfg.loadVfioPci
        then ["vfio_virqfd" "vfio_pci" "vfio_iommu_type1" "vfio"]
        else [];
      initrd.availableKernelModules =
        if cfg.loadVfioPci
        then ["vfio-pci"]
        else [];
    };
  };
}
