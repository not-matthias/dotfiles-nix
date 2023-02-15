# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  pkgs,
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  # Fix brightness keys and enable deep sleep
  boot.kernelParams = ["module_blacklist=hid_sensor_hub" "mem_sleep_default=deep"];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e33d79b0-4de1-47d3-a3fe-ab53c3f7f390";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-b1731fc9-3d03-44aa-83b7-9061aba94621".device = "/dev/disk/by-uuid/b1731fc9-3d03-44aa-83b7-9061aba94621";

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/4A19-036A";
    fsType = "vfat";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/8feea14d-3406-4e2f-9608-f36ad9082e4b";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp166s0.useDHCP = lib.mkDefault true;

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
  };
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
