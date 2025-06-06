{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hardware.sound;
in {
  options.hardware.sound = {
    enable = lib.mkEnableOption "Enables sound support";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull;
    };
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
