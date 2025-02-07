{
  lib,
  config,
  ...
}: let
  cfg = config.services.kokoro;
in {
  options.services.kokoro = {
    enable = lib.mkEnableOption "Kokoro TTS";
    useGpu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use GPU for Kokoro TTS";
    };
    ui-port = lib.mkOption {
      type = lib.types.int;
      default = 7860;
      description = "Port for the Kokoro UI";
    };
    api-port = lib.mkOption {
      type = lib.types.int;
      default = 8880;
      description = "Port for the Kokoro API";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "v0.2.0";
      description = "Version of the Kokoro TTS";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = let
      image-name =
        if cfg.useGpu
        then "ghcr.io/remsky/kokoro-fastapi-gpu:${cfg.version}"
        else "ghcr.io/remsky/kokoro-fastapi-cpu:${cfg.version}";
    in {
      kokoro = {
        image = "${image-name}";
        ports = ["${toString cfg.api-port}:8880"];
        volumes = ["/var/lib/kokoro/voices:/app/api/src/voices"];
        environment = {
          PYTHONPATH = "/app:/app/models";
        };
        extraOptions =
          if cfg.useGpu
          then ["--device=nvidia.com/gpu=all"]
          else []; # "--gpus=all"
      };

      kokoro-ui = {
        image = "ghcr.io/remsky/kokoro-fastapi-ui:v0.1.0";
        ports = ["${toString cfg.ui-port}:7860"];
        volumes = ["/var/lib/kokoro/data:/app/ui/data"];
        environment = {
          PYTHONUNBUFFERED = "1";
          DISABLE_LOCAL_SAVING = "false";
        };
        extraOptions = ["--add-host=kokoro-tts:10.88.0.1"];
      };
    };
  };
}
