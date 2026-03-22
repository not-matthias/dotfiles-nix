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
      "vm.overcommit_memory" = lib.mkDefault 1;
      "vm.overcommit_ratio" = 50;

      # Additional laptop-mode-tools inspired settings
      # Longer dirty expire time when in laptop mode
      "vm.dirty_expire_centisecs" = 3000;
    };

    services = {
      power-profiles-daemon.enable = false;
      thermald.enable = true;
      # Disable TLP — nixos-hardware's framework module enables it, but it conflicts
      # with auto-cpufreq and overrides our governor/EPP/sysctl settings on battery.
      tlp.enable = lib.mkForce false;
    };
    programs.auto-cpufreq = {
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

    powerManagement = {
      enable = true;
      powertop.enable = true;
      cpuFreqGovernor = lib.mkDefault "performance";
    };

    programs.fish.shellAbbrs = {
      "cpuf" = "sudo systemctl restart auto-cpufreq.service";
    };
  };
}
