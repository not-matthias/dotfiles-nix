{
  unstable,
  config,
  lib,
  ...
}: let
  cfg = config.services.ollama;
in {
  options.services.ollama = {
    useNvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Whether to use NVIDIA for inference";
    };
  };

  # Only enable if ollama is enabled
  config = lib.mkIf cfg.enable {
    services.ollama = {
      # enable = false; # This will be enabled by the user.
      package = unstable.ollama;
      acceleration =
        if cfg.useNvidia
        then "cuda"
        else "";
    };

    services.open-webui = {
      enable = cfg.enable;
      package = unstable.open-webui;
      host = "0.0.0.0";
      port = 11435;
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";

        SCARF_NO_ANALYTICS = "True";
        DO_NOT_TRACK = "True";
        ANONYMIZED_TELEMETRY = "False";

        #ENABLE_COMMUNITY_SHARING = "False";
        #ENABLE_ADMIN_EXPORT = "False";
      };
    };
  };
}
