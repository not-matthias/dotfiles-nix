{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.services.ollama;
  unstable = pkgs;
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
  };
}
