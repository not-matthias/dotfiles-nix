{
  lib,
  config,
  ...
}: let
  cfg = config.hardware.sound;
in {
  options.hardware.sound = {
    enable = lib.mkEnableOption "Enables sound support";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    hardware.pulseaudio.enable = false;
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
