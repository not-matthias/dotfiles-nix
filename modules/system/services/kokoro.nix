{
  lib,
  config,
  domain,
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
      default = "v0.2.4";
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

      # FIXME: This doesn't work because the `kokoro-tts` dns can't be resolved
      # kokoro-ui = {
      #   image = "ghcr.io/remsky/kokoro-fastapi-ui:v0.1.0";
      #   ports = ["7860:7860"];
      #   dependsOn = ["kokoro-tts"];
      #   environment = {
      #     PYTHONUNBUFFERED = "1";
      #     DISABLE_LOCAL_SAVING = "false";
      #     API_HOST = "kokoro-tts";
      #     API_PORT = "8880";
      #   };
      #   extraOptions = ["--network=host"];
      # };
    };

    services.caddy.virtualHosts."kokoro.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:7860
    '';
  };
}
