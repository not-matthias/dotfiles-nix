{
  config,
  pkgs,
  user,
  ...
}: {
  # Add libvirtd and kvm to userGroups
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
  '';
  #   boot.extraModprobeConfig = ''
  #     options kvm_amd nested=1
  #     options kvm_amd emulate_invalid_guest_state=0
  #     options kvm ignore_nsrs=1
  #   '';                                         # Needed to run OSX-KVM

  users.groups.libvirtd.members = ["root" "${user}"];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        verbatimConfig = ''
          nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
        '';
        package = pkgs.qemu_kvm;
      };
    };
    spiceUSBRedirection.enable = true; # USB passthrough
  };

  environment = {
    systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      qemu
      OVMF
      gvfs # Used for shared folders between linux and windows
    ];
  };

  services = {
    # Enable file sharing between OS
    gvfs.enable = true;
  };

  #boot ={
  #  kernelParams = [ "intel_iommu=on" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];      # or amd_iommu (cpu)
  #  kernelModules = [ "vendor-reset" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd"];
  #  extraModulePackages = [ config.boot.kernelPackages.vendor-reset ]; # Presumably fix for GPU Reset Bug
  #  extraModprobeConfig = "options vfio-pci ids=1002:67DF,1002:AAF0"; # grep PCI_ID /sys/bus/pci/devices/*/uevent
  #  kernelPatches = [
  #    {
  #    name = "vendor-reset-reqs-and-other-stuff";
  #    patch = null;
  #    extraConfig = ''
  #    FTRACE y
  #    KPROBES y
  #    FUNCTION_TRACER y
  #    HWLAT_TRACER y
  #    TIMERLAT_TRACER y
  #    IRQSOFF_TRACER y
  #    OSNOISE_TRACER y
  #    PCI_QUIRKS y
  #    KALLSYMS y
  #    KALLSYMS_ALL y
  #    '';
  #    }
  #  ];
  #};
}
