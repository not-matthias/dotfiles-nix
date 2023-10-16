# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # boot.kernelPackages = pkgs.linuxPackages_latest; # Can't use latest kernel because of vmware
  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  # Fix brightness keys and enable deep sleep
  boot.kernelParams = [
    "module_blacklist=hid_sensor_hub"
    # For Power consumption
    # https://kvark.github.io/linux/framework/2021/10/17/framework-nixos.html
    "mem_sleep_default=deep"
    # For Power consumption
    # https://community.frame.work/t/linux-battery-life-tuning/6665/156
    "nvme.noacpi=1"
    # https://community.frame.work/t/solved-bluetooth-mouse-lag-linux-autosuspend/26763
    "btusb.enable_autosuspend=n"
    # https://community.frame.work/t/periodic-1sec-mouse-pointer-freeze-events/13155
    # https://community.frame.work/t/periodic-stuttering-on-fresh-gnome-40-wayland-install-on-arch-linux/3912
    "i915.enable_psr=0"
    # https://askubuntu.com/questions/763413/how-can-i-get-rid-of-mouse-lag-under-ubuntu
    "usbhid.mousepoll=1"
  ];

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

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
