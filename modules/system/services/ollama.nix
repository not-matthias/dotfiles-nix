{
  unstable,
  pkgs,
  config,
  lib,
  domain,
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
      #enable = true;
      # enable = false; # This will be enabled by the user.
      package =
        if cfg.useNvidia
        then unstable.ollama-cuda
        else unstable.ollama;
      acceleration =
        if cfg.useNvidia
        then "cuda"
        else null;
      host = "0.0.0.0";
    };

    services.open-webui = {
      enable = true;
      package = pkgs.open-webui;
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

    services.caddy.virtualHosts."ollama.${domain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:11435
    '';

    services.restic = {
      paths = [
        "/var/lib/open-webui"
        "/var/lib/private/open-webui"
      ];
      excludes = [
        "/var/lib/open-webui/models-*"
        "/var/lib/open-webui/hub"
        "/var/lib/open-webui/cache"
      ];
    };
  };
}
