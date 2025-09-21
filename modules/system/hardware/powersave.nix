# Based on these:
# - https://wiki.archlinux.org/title/Power_management and
# - https://gist.github.com/LarryIsBetter/218fda4358565c431ba0e831665af3d1
#
# Other references:
# - https://github.com/bendlas/nixos-config/blob/d05515c44257ef4b06bfc4020e556204ef128873/power-savings.nix#L15
# - https://github.com/Baitinq/nixos-config/blob/79e683455118545ac5c4a2ad7c6101b94debf07f/modules/power-save/default.nix#L18
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hardware.powersave;
in {
  options.hardware.powersave = {
    enable = lib.mkEnableOption "Powersave Configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      powertop
      hdparm
      iw
      ethtool
    ];

    boot = {
      # snd_hda_intel: Audio Power saving
      # iwlwifi: https://wiki.archlinux.org/title/Power_management#Intel_wireless_cards_(iwlwifi)
      extraModprobeConfig = ''
        options snd_hda_intel power_save=1
        options iwlwifi power_save=1 d0i3_disable=0 uapsd_disable=0
        options iwlmvm power_scheme=3
      '';

      kernel.sysctl = {
        # Disable Watchdog, can lead to significant power savings
        # See: https://wiki.archlinux.org/title/Power_management#Disabling_NMI_watchdog
        "kernel.nmi_watchdog" = 0;

        # https://lonesysadmin.net/2013/12/22/better-linux-disk-caching-performance-vm-dirty_ratio/
        # https://askubuntu.com/questions/847703/how-to-change-the-value-of-dirty-writeback-centisecs
        # https://wiki.archlinux.org/title/Power_management#Writeback_Time
        "vm.dirty_writeback_centisecs" = 1500;

        # Swap to disk less
        "vm.swappiness" = 1;

        # https://www.kernel.org/doc/Documentation/laptops/laptop-mode.txt
        "vm.laptop_mode" = 5;

        # Optimize dirty page ratios for SSD
        "vm.dirty_ratio" = 3;
        "vm.dirty_background_ratio" = 1;

        # Memory overcommit settings to reduce swap usage
        "vm.overcommit_memory" = 1;
        "vm.overcommit_ratio" = 50;

        # Additional laptop-mode-tools inspired settings
        # Longer dirty expire time when in laptop mode
        "vm.dirty_expire_centisecs" = 3000;

        # Network power management
        "net.core.default_qdisc" = "fq_codel";

        # Reduce network buffer sizes to save memory
        "net.core.rmem_default" = 262144;
        "net.core.wmem_default" = 262144;
      };
    };

    # Prevent overheating on Intel cpus
    services.thermald.enable = true;

    services.auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";

          # Maximize battery
          energy_performance_preference = "power";
          energy_perf_bias = "power";
          scaling_min_freq = 400000;
          scaling_max_freq = 800000;

          # Battery charge threshold
          enable_thresholds = true;
          start_threshold = 20;
          stop_threshold = 80;
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    powerManagement = {
      enable = true;
      powertop.enable = true;
      cpuFreqGovernor = lib.mkDefault "powersave";
    };

    # Runtime power management for storage devices
    boot.kernelParams = [
      # Enable runtime PM for SATA devices
      "scsi_mod.use_blk_mq=1"
    ];

    # Power management commands to enable runtime PM for storage
    powerManagement.powerUpCommands = ''
      # Enable runtime PM for all SATA devices
      for dev in /sys/class/scsi_host/host*/link_power_management_policy; do
        if [ -w "$dev" ]; then
          echo min_power > "$dev" 2>/dev/null || true
        fi
      done

      # Enable runtime PM for NVMe devices
      for dev in /sys/class/nvme/nvme*/power/control; do
        if [ -w "$dev" ]; then
          echo auto > "$dev" 2>/dev/null || true
        fi
      done

      # Enable runtime PM for block devices (including sda)
      for dev in /sys/block/sd*/device/power/control; do
        if [ -w "$dev" ]; then
          echo auto > "$dev" 2>/dev/null || true
        fi
      done

      # Disk power management (laptop-mode-tools style)
      # Set aggressive power management for SATA drives
      for disk in /dev/sd?; do
        if [ -b "$disk" ]; then
          ${pkgs.hdparm}/bin/hdparm -B 1 -S 120 "$disk" 2>/dev/null || true
        fi
      done

      # Network power management
      # Enable power saving for wireless interfaces
      for iface in /sys/class/net/w*; do
        if [ -d "$iface" ]; then
          iface_name=$(basename "$iface")
          ${pkgs.iw}/bin/iw dev "$iface_name" set power_save on 2>/dev/null || true
        fi
      done

      # Disable Wake-on-LAN for ethernet interfaces
      for iface in /sys/class/net/e*; do
        if [ -d "$iface" ]; then
          iface_name=$(basename "$iface")
          ${pkgs.ethtool}/bin/ethtool -s "$iface_name" wol d 2>/dev/null || true
        fi
      done
    '';

    # See:
    # https://knowledgebase.frame.work/optimizing-ubuntu-battery-life-Sye_48Lg3
    # https://github.com/nzbr/nixos/blob/cd219d6e0bd968f749cd74a9289800b9e67775c0/module/pattern/laptop.nix#L13-L22
    # https://github.com/krebs/stockholm/blob/40f103e9ccf99dc36c92e2e008ed7a0b3dca1f48/makefu/2configs/hw/tp-x2x0.nix#L41-L50
    # - https://wiki.archlinux.org/title/CPU_frequency_scaling
    #
    services.power-profiles-daemon.enable = false;
    services.tlp = {
      enable = false;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        # Save long term battery health
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;

        RUNTIME_PM_ON_BAT = "auto";

        # tlp-stat -g
        # INTEL_GPU_MIN_FREQ_ON_AC = 500;
        # INTEL_GPU_MIN_FREQ_ON_BAT = 500;
        #
      };
    };
  };
}
