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
    ];

    boot.kernel.sysctl = {
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
    };

    services = {
      power-profiles-daemon.enable = false;
      thermald.enable = true;
      auto-cpufreq = {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            turbo = "never";

            # Maximize battery
            energy_performance_preference = "power";
            energy_perf_bias = "power";
            scaling_min_freq = 400000;
            scaling_max_freq = 1200000;
          };
          charger = {
            governor = "performance";
            turbo = "auto";
          };
        };
      };
    };

    powerManagement = {
      enable = true;
      powertop.enable = true;
      cpuFreqGovernor = lib.mkDefault "performance";
    };

    # services.udev.extraRules = ''
    #   # USB autosuspend blacklist

    #   # Logitech G502 mouse
    #   ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="062a", ATTR{idProduct}=="5918", GOTO="power_usb_rules_end"

    #   # Enable USB autosuspend by default for all other devices.
    #   #ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    #   LABEL="power_usb_rules_end"
    # '';

    # boot.extraModprobeConfig = mkIf cfg.disableMouseAutosuspend ''
    #   # Increase autosuspend delay for USB devices to 5 seconds (default is 2)
    #   # This gives USB hubs more time to remain active for input events
    #   options usbcore autosuspend=15
    # '';
  };
}
