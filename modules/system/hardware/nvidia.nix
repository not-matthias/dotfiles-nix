# References:
# - https://github.com/viperML/dotfiles/blob/62fac868c54b471803f234d1eef8b76b3ed66ba0/modules/nixos/hardware-nvidia.nix
{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hardware.nvidia;
in {
  options.hardware.nvidia = {
    enable = lib.mkEnableOption "Nvidia Configuration";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = ["nvidia"];

    boot = {
      blacklistedKernelModules = ["nouveau"];

      # Use nvidia framebuffer
      # https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers#Kernel_module_parameters for more info.
      kernelParams = ["nvidia-drm.fbdev=1"];
    };

    hardware = {
      # Enable the nvidia-container-toolkit for Docker
      nvidia-container-toolkit.enable = true;

      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.latest;
        powerManagement.enable = true;
        modesetting.enable = true;
        open = false;
        nvidiaSettings = true;
      };
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
          nvidia-vaapi-driver
        ];
        extraPackages32 = with pkgs.pkgsi686Linux; [
          vaapiVdpau
          libvdpau-va-gl
          nvidia-vaapi-driver
        ];
      };
    };

    # Untested:
    #services.xserver.screenSection = ''
    #  Option         "UseNvKmsCompositionPipeline" "false"
    #  Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On,AllowGSYNCCompatible=On}"
    #'';
    # services.xserver.screenSection = ''
    #   Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    #   Option         "AllowIndirectGLXProtocol" "off"
    #   Option         "TripleBuffer" "on"
    # '';
  };
}
