{
  lib,
  config,
  ...
}: let
  cfg = config.services.kokoro;
in {
  options.services.kokoro = {
    enable = lib.mkEnableOption "Kokoro TTS";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker.enable = true;
      oci-containers.containers = let
        kokoro_version = "v0.1.0";
        kokoro_api_port = 8880;
        kokoro_ui_port = 7860;
      in {
        kokoro = {
          image = "ghcr.io/remsky/kokoro-fastapi-gpu:${kokoro_version}";
          ports = ["${toString kokoro_api_port}:8880"];
          volumes = ["/var/lib/kokoro/voices:/app/api/src/voices"];
          devices = ["nvidia.com/gpu=0"];
          environment = {
            PYTHONPATH = "/app:/app/models";
          };
        };
        kokoro-ui = {
          image = "ghcr.io/remsky/kokoro-fastapi-ui:${kokoro_version}";
          ports = ["${toString kokoro_ui_port}:7860"];
          volumes = ["/var/lib/kokoro/data:/app/ui/data"];
          environment = {
            PYTHONUNBUFFERED = "1";
            DISABLE_LOCAL_SAVING = "false";
          };
          extraOptions = ["--add-host=kokoro-tts:10.88.0.1"];
        };
      };
    };
  };
}
