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

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  # =============================== ZFS START ===============================

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = ["zfs"];
  boot.zfs = {
    forceImportRoot = false; # Enabled by default, recommended to turn off.

    allowHibernation = false;
    extraPools = [
      "backup-pool"
      "storage-pool"
    ];
    devNodes = "/dev/disk/by-partuuid"; # Makes sure the device can be found on boot
  };
  networking.hostId = "d6e46ab6";

  #boot.kernelParams = ["zfs.zfs_arc_max=12884901888"];
  # zfs_arc_max = use ARC up to 2GiB
  # boot.extraModprobeConfig = ''
  #   options zfs l2arc_noprefetch=0 l2arc_write_boost=33554432 l2arc_write_max=16777216 zfs_arc_max=2147483648
  # '';

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;

    # https://github.com/openzfs/zfs/blob/master/cmd/zed/zed.d/zed.rc
    zed.settings = {
      ZED_DEBUG_LOG = "/tmp/zed.debug.log";
      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_NTFY_TOPIC = "desktop-zfs";
      ZED_NTFY_URL = "https://ntfy.sh";
    };
  };

  #fileSystems."/mnt/backup" = {
  #  device = "backup-pool";
  #  fsType = "zfs";
  #};

  #  fileSystems."/mnt/data/personal" =
  #    { device = "storage-pool/personal";
  #      fsType = "zfs";
  #    };

  #  fileSystems."/mnt/data/technical" =
  #    { device = "storage-pool/technical";
  #      fsType = "zfs";
  #    };

  # =============================== ZFS END ===============================

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/a470e6c4-55ec-40c8-ab57-45954d23b35d";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-3657bc7a-4bff-43e2-826d-c4d6edc59b96".device = "/dev/disk/by-uuid/3657bc7a-4bff-43e2-826d-c4d6edc59b96";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/69A5-E578";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/5911ac7d-bdab-42ac-b35b-868bec124f66";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp34s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
