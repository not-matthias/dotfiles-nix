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

  sysctlBin = "${pkgs.procps}/bin/sysctl";

  # dirty_ratio            - % of RAM allowed dirty before processes block on writes
  # dirty_background_ratio - % of RAM allowed dirty before background flushing starts
  # dirty_writeback_centisecs - how often the kernel flusher wakes up (in 1/100s)
  # dirty_expire_centisecs - how long dirty pages stay in memory before forced write (in 1/100s)
  # laptop_mode            - batches disk writes to allow longer disk idle time (0=off, 5=aggressive)
  # swappiness             - how aggressively the kernel swaps pages to disk (0-200, lower=less swap)
  # overcommit_memory      - 0=heuristic deny, 1=always allow (risks OOM), 2=strict limit
  # overcommit_ratio       - % of RAM for overcommit (only applies when overcommit_memory=2)
  # vfs_cache_pressure     - how aggressively the kernel reclaims inode/dentry caches (lower=keep longer)
  #
  # References:
  # - https://lonesysadmin.net/2013/12/22/better-linux-disk-caching-performance-vm-dirty_ratio/
  # - https://wiki.archlinux.org/title/Power_management#Writeback_Time
  # - https://www.kernel.org/doc/Documentation/laptops/laptop-mode.txt
  powerSysctlScript = pkgs.writeShellScript "power-sysctl" ''
    ${sysctlBin} vm.dirty_ratio=10
    ${sysctlBin} vm.dirty_background_ratio=5
    ${sysctlBin} vm.dirty_writeback_centisecs=500
    ${sysctlBin} vm.dirty_expire_centisecs=1500
    ${sysctlBin} vm.laptop_mode=0
    ${sysctlBin} vm.swappiness=10
    ${sysctlBin} vm.overcommit_memory=0
    ${sysctlBin} vm.vfs_cache_pressure=50
  '';

  ppdSwitch = pkgs.writeShellScript "ppd-ac-switch" ''
    ppdctl="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    "$ppdctl" configure-battery-aware --disable
    "$ppdctl" set performance || "$ppdctl" set balanced
  '';
in {
  options.hardware.powersave = {
    enable = lib.mkEnableOption "Powersave Configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      powertop
      power-profiles-daemon
    ];

    boot.kernel.sysctl = {
      # Disable Watchdog, can lead to significant power savings
      # See: https://wiki.archlinux.org/title/Power_management#Disabling_NMI_watchdog
      "kernel.nmi_watchdog" = 0;
    };

    # Apply correct sysctl profile on boot
    systemd.services.power-sysctl = {
      description = "Apply power-aware sysctl values";
      wantedBy = ["multi-user.target"];
      after = ["sysinit.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = powerSysctlScript;
      };
    };

    services = {
      power-profiles-daemon.enable = true;
      thermald.enable = false;
      # Disable TLP — nixos-hardware's framework module enables it, but it conflicts
      # with auto-cpufreq and overrides our governor/EPP/sysctl settings on battery.
      tlp.enable = lib.mkForce false;
    };

    systemd.services.ppd-ac-switch = {
      description = "Select performance power profile";
      wantedBy = ["multi-user.target"];
      after = ["power-profiles-daemon.service"];
      wants = ["power-profiles-daemon.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ppdSwitch;
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ACTION=="change", ATTR{type}=="Mains", RUN+="${pkgs.systemd}/bin/systemctl start --no-block ppd-ac-switch.service"
    '';

    powerManagement = {
      enable = true;
      powertop.enable = false;
      cpuFreqGovernor = lib.mkDefault "performance";
    };
  };
}
