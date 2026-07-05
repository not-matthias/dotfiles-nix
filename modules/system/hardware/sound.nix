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
      wireplumber = {
        enable = true;
        extraConfig = {
          "10-bluetooth" = {
            "wireplumber.settings" = {
              "bluetooth.autoswitch-to-headset-profile" = false;
            };
            "monitor.bluez.rules" = [
              {
                matches = [
                  {"device.name" = "~bluez_card.*";}
                ];
                actions = {
                  "update-props" = {
                    "device.profile.switch-on-connect" = true;
                    "bluez5.auto-connect" = ["a2dp_sink"];
                    "bluez5.hw-volume" = ["hfp_hf" "a2dp_sink"];
                  };
                };
              }
            ];
            "monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-hw-volume" = true;
              "bluez5.roles" = ["a2dp_sink" "a2dp_source" "hfp_ag" "hfp_hf" "bap_sink" "bap_source"];
            };
          };
          # Use software mixer instead of hardware mixer for ALSA outputs.
          # Prevents L/R channel imbalance when adjusting volume, which is
          # a known issue on some hardware (e.g. Framework laptops).
          "12-alsa-soft-mixer" = {
            "monitor.alsa.rules" = [
              {
                matches = [
                  {"node.name" = "~alsa_output.*";}
                ];
                actions = {
                  "update-props" = {
                    "api.alsa.soft-mixer" = true;
                  };
                };
              }
            ];
          };
        };
      };
    };
  };
}
