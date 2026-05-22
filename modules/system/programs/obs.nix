{
  pkgs,
  config,
  lib,
  user,
  ...
}: let
  cfg = config.programs.obs;
in {
  options.programs.obs = {
    enable = lib.mkEnableOption "OBS Studio with plugins";

    virtualCamera = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Load v4l2loopback so OBS's virtual camera shows up as /dev/video*.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = lib.mkIf cfg.virtualCamera {
      extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
      kernelModules = ["v4l2loopback"];
      extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
      '';
    };

    home-manager.users.${user} = {
      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-vaapi
          obs-vkcapture
          obs-gstreamer
          obs-pipewire-audio-capture
        ];
      };
    };
  };
}
