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
      power-profiles-daemon
    ];

    services = {
      tuned = {
        enable = true;
        # Keep this desktop profile static; the profile is selected explicitly
        # through tuned-ppd rather than by TuneD's workload monitor.
        settings.dynamic_tuning = false;
        ppdSettings = {
          main = {
            default = "performance";
            # With an 80% charge limit, the battery reports "Not charging"
            # while AC is connected. tuned-ppd then flaps between AC and DC
            # profiles instead of keeping the selected performance profile.
            battery_detection = false;
          };
          profiles = {
            power-saver = "framework-battery";
            balanced = "balanced";
            performance = "framework-performance";
          };
          battery = {
            balanced = "balanced-battery";
            # On battery, downgrade PPD "performance" from framework-performance
            # to stock `balanced`. Can't map to framework-battery — that collides
            # with profiles.power-saver and breaks tuned-ppd's injectivity
            # requirement (config.py:138), which needs a reversible PPD<->TuneD
            # mapping. framework-ultra-powersave would be injective but is
            # deliberately kept off the PPD surface (see profiles comment).
            performance = "balanced";
          };
        };
        # Custom profile: throughput-performance + vm sysctl tuning previously
        # applied by the power-sysctl oneshot service. Byte-based dirty
        # thresholds (not ratios) so writeback limits stay fixed regardless of
        # installed RAM.
        profiles.framework-performance = {
          main.include = "throughput-performance";
          vm_tuning = {
            type = "sysctl";
            replace = true;
            "vm.dirty_bytes" = 536870912; # 512MB, was dirty_ratio 10%
            "vm.dirty_background_bytes" = 268435456; # 256MB, was dirty_background_ratio 5%
            "vm.dirty_writeback_centisecs" = 500;
            "vm.dirty_expire_centisecs" = 1500;
            "vm.laptop_mode" = 0;
            "vm.swappiness" = 1; # avoid proactive swap-out; 1 not 0 to keep OOM killer preferring swap on some kernels
            "vm.overcommit_memory" = 0;
            "vm.vfs_cache_pressure" = 25; # retain more dentry/inode cache for git/LSP indexing
          };
        };
        # Aggressive battery profile: laptop-battery-powersave + PCI runtime PM,
        # SMT disable, nmi_watchdog off, per-device power saving.
        # Adapted from https://github.com/isning/nix-config
        profiles.framework-battery = {
          main.include = "laptop-battery-powersave";
          cpu = {
            energy_perf_bias = "power";
            boost = "1";
            force_latency = "None"; # allow deep C-states
          };
          sysfs = {
            # PCI runtime PM — lets unused controllers enter D3cold
            "/sys/bus/pci/devices/*/power/control" = "auto";
            "/sys/bus/pci/devices/*/power/autosuspend_delay_ms" = "0";
            "/sys/firmware/acpi/platform_profile" = "low-power";
            "/sys/module/pcie_aspm/parameters/policy" = "powersave";
            # Disable SMT on battery — fewer active threads, lower power
            "/sys/devices/system/cpu/smt/control" = "off";
          };
          battery_sysctl = {
            type = "sysctl";
            replace = true;
            "kernel.nmi_watchdog" = "0"; # reduce periodic wakeups
            # Byte-based (not ratio) for the same reason as framework-performance:
            # mixing ratio- and byte-based dirty knobs across profiles that tuned
            # switches between dynamically risks one form being left at 0.
            "vm.dirty_bytes" = "134217728"; # 128MB, was dirty_ratio 5%
            "vm.dirty_background_bytes" = "33554432"; # 32MB, was dirty_background_ratio 2%
          };
          audio.timeout = "1";
          disk.readahead = "256";
          usb.autosuspend = "1";
        };
        # Ultra-powersave: stacks on framework-battery with turbo disabled and a
        # hard clock ceiling. Opt-in only via `tuned-adm profile
        # framework-ultra-powersave` (PPD exposes only power-saver/balanced/
        # performance, so this is not reachable through powerprofilesctl).
        # Expect single-thread sluggishness — emergency/flight use, not daily.
        profiles.framework-ultra-powersave = {
          main.include = "framework-battery";
          cpu.boost = "0"; # framework-battery keeps boost=1; ultra kills turbo spikes
          sysfs."/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq" = "1800000"; # 1.8 GHz hard ceiling, above scaling_min_freq (1.1 GHz)
        };
      };
      thermald.enable = false;
      # nixos-hardware's framework module enables TLP, which conflicts with tuned
      # and overrides our governor/EPP/sysctl settings on battery.
      tlp.enable = lib.mkForce false;
    };
    # tuned-ppd ships WantedBy=graphical.target, but this host has no display
    # manager so graphical.target never activates. Force multi-user.target so
    # the PPD compat layer (ppdSettings default profile + battery_detection +
    # the powerprofilesctl D-Bus name) is live at boot.
    systemd.services.tuned-ppd.wantedBy = lib.mkForce ["multi-user.target"];

    powerManagement = {
      enable = true;
      powertop.enable = false;
      cpuFreqGovernor = lib.mkDefault "performance";
    };
  };
}
