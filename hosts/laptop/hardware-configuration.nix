# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  unstable,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelPackages = unstable.linuxPackages_latest;
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3a71b953-9330-4929-a35f-4a17973186b2";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-b9eeb412-f2ac-42e5-adf6-88aa1e4cab73".device = "/dev/disk/by-uuid/b9eeb412-f2ac-42e5-adf6-88aa1e4cab73";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/DE67-F487";
    fsType = "vfat";
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/76afac4e-db81-47f3-bf0a-28969e0c56fb";
    options = ["nosuid" "nodev" "nofail" "x-gvfs-show"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/1965b4ab-ece0-4246-9a21-86262af7c5b7";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
