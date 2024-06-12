{lib, ...}: {
  imports = [(import ./hardware-configuration.nix)];

  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
  };
  hardware.intel.enable = true;
  virtualisation.vfio = {
    enable = true;
    IOMMUType = "intel";
    enableNestedVirt = true;
  };
  desktop.hyprland.enable = true;

  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    initrd = {
      # Setup keyfile
      secrets."/crypto_keyfile.bin" = null;

      # Enable swap on luks
      luks.devices."luks-482bfe5c-c987-4a97-9c07-b8cd312cabb5".device = "/dev/disk/by-uuid/482bfe5c-c987-4a97-9c07-b8cd312cabb5";
      luks.devices."luks-482bfe5c-c987-4a97-9c07-b8cd312cabb5".keyFile = "/crypto_keyfile.bin";
    };
  };

  # https://wiki.archlinux.org/title/Solid_state_drive#TRIM
  # - SDs benefit from informing the disk controller when blocks of memory are free to be reused
  services.fstrim.enable = true;

  # See:
  # https://knowledgebase.frame.work/optimizing-ubuntu-battery-life-Sye_48Lg3
  # https://github.com/nzbr/nixos/blob/cd219d6e0bd968f749cd74a9289800b9e67775c0/module/pattern/laptop.nix#L13-L22
  # https://github.com/krebs/stockholm/blob/40f103e9ccf99dc36c92e2e008ed7a0b3dca1f48/makefu/2configs/hw/tp-x2x0.nix#L41-L50
  # - https://wiki.archlinux.org/title/CPU_frequency_scaling
  #
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # CPU Settings
      #
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Set Intel P-state performance: 0..100 (%)
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 30;

      # Set the CPU "turbo boost" feature
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Set the CPU HWP dynamic boost feature
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Minimize number of used cpu cores/hyper-threads under light load conditions
      SCHED_POWERSAVE_ON_AC = 1;
      SCHED_POWERSAVE_ON_BAT = 1;

      # Kernel NMI Watchdog
      NMI_WATCHDOG = 0;

      # Platform Profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      START_CHARGE_THRESH_BAT0 = 90;
      STOP_CHARGE_THRESH_BAT0 = 97;
      RUNTIME_PM_ON_BAT = "auto";

      # USB Settings
      #
      USB_AUTOSUSPEND = 1;
      USB_EXCLUDE_AUDIO = 1;
      USB_EXCLUDE_BTUSB = 0;
      USB_EXCLUDE_PHONE = 0;
      USB_EXCLUDE_PRINTERS = 1;
      USB_EXCLUDE_WWAN = 0;
      USB_AUTOSUSPEND_DISABLE_ON_SHUTDOWN = 0;
    };
  };
  services.auto-cpufreq = {
    enable = true;
    # https://github.com/AdnanHodzic/auto-cpufreq/blob/master/auto-cpufreq.conf-example
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
    };
  };
  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
  };
}
