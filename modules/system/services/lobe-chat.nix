{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.lobe-chat;
in {
  options.services.lobe-chat = {
    enable = lib.mkEnableOption "LobeChat AI conversation interface";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      "lobe-chat" = {
        image = "docker.io/lobehub/lobe-chat:latest";
        environment = {
          "OLLAMA_PROXY_URL" = "http://127.0.0.1:11434";
        };
        ports = ["11433:3210/tcp"];
        extraOptions = [
          "--pull=always"
          "--network=host"
        ];
      };
    };

    services.caddy.virtualHosts."lobe-chat.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11433
    '';

    # services.restic.paths = [
    #   "/var/lib/containers/storage/volumes/lobe-chat-data"
    # ];
  };
}
