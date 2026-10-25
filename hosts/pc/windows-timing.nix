# Build-only test boot for PR17 timing while retaining the desktop GPU.
# Select this generation only after reviewing the build and arranging a restart.
# It deliberately does not enable the full VFIO/domain module or autostart Windows.
{
  flakes,
  lib,
  pkgs,
  ...
}: let
  kernel = flakes.win11-kvm.packages.${pkgs.stdenv.hostPlatform.system}.kernel;
  # Initial calibration candidate shared by desktop and VFIO test boots.
  divisor = 64;
in {
  specialisation.windows-vfio.configuration.virtualisation.win11-kvm.settings = {
    rdtsc_spoofing = true;
    rdtsc_divisor = divisor;
    handler_time_compensation = false;
    cpuid_fastpath = true;
  };

  specialisation.windows-timing.configuration = {config, ...}: {
    boot.kernelPackages = lib.mkOverride 40 (pkgs.linuxPackagesFor kernel);
    boot.kernelParams = [
      # Starting calibration candidate, not a validated Windows latency target.
      "kvm_amd.rdtsc_experiment=1"
      "kvm_amd.rdtsc_divisor=${toString divisor}"
      "kvm_amd.handler_time_compensation=0"
      "kvm_amd.cpuid_fastpath=1"
      "kvm_amd.cpuid_passthrough=0"
      "kvm_amd.experimental_debug_passthrough=0"
    ];
    system.nixos.tags = ["windows-timing-d${toString divisor}"];
    virtualisation.libvirtd.onBoot = lib.mkForce "ignore";
    assertions = [
      {
        assertion = !config.virtualisation.win11-kvm.enable;
        message = "windows-timing must not enable the full VFIO/domain module; use the existing VM with a temporary GPU-free definition.";
      }
      {
        assertion =
          !(builtins.elem "amdgpu" config.boot.blacklistedKernelModules)
          && !(builtins.elem "radeon" config.boot.blacklistedKernelModules)
          && !(lib.any (p: lib.hasPrefix "vfio-pci.ids=" p) config.boot.kernelParams)
          && !(builtins.elem "initcall_blacklist=sysfb_init" config.boot.kernelParams);
        message = "windows-timing must preserve the host GPU and framebuffer; remove conflicting VFIO boot settings.";
      }
    ];
  };
}
