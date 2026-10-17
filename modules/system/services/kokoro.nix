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
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "v0.8.1";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = let
      image-name =
        if cfg.useGpu
        then "ghcr.io/remsky/kokoro-fastapi-gpu:${cfg.version}"
        else "ghcr.io/remsky/kokoro-fastapi-cpu:${cfg.version}";
    in {
      kokoro-tts = {
        image = "${image-name}";
        ports = ["8880:8880"];
        environment = {
          PYTHONPATH = "/app:/app/api";
          PYTHONUNBUFFERED = "1";
        };
        extraOptions =
          ["--network=host"]
          ++ (
            if cfg.useGpu
            then ["--device=nvidia.com/gpu=all"]
            else []
          );
      };
    };
  };
}
