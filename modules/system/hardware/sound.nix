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
          "10-auto-switch" = {
            "monitor.bluez.rules" = [
              {
                matches = [
                  {"device.name" = "~bluez_card.*";}
                ];
                actions = {
                  "update-props" = {
                    "device.profile.switch-on-connect" = true;
                  };
                };
              }
            ];
          };
          "11-bluetooth-policy" = {
            "wireplumber.profiles" = {
              "bluetooth" = {
                "inherits" = ["main"];
                "bluetooth.autoswitch-to-headset-profile" = true;
                "bluetooth.default-node-auto-switch" = true;
              };
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
          "13-bluetooth-volume" = {
            "monitor.bluez.rules" = [
              {
                matches = [
                  {"device.name" = "~bluez_card.*";}
                ];
                actions = {
                  "update-props" = {
                    "bluez5.auto-connect" = ["hfp_hf" "hsp_hs" "a2dp_sink"];
                    "bluez5.hw-volume" = ["hfp_hf" "hsp_hs" "a2dp_sink"];
                  };
                };
              }
            ];
            "monitor.bluez.properties" = {
              "bluez5.enable-sbc-xq" = true;
              "bluez5.enable-hw-volume" = true;
            };
          };
        };
      };
    };
  };
}
