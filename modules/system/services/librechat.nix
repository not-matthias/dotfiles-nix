{
  config,
  lib,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.librechat;
in {
  options.services.librechat = {
    enable = lib.mkEnableOption "LibreChat AI conversation interface";
    port = lib.mkOption {
      type = lib.types.int;
      default = 11437;
      description = "Port for LibreChat to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      librechat = {
        image = "ghcr.io/danny-avila/librechat:latest";
        environment = {
          HOST = "0.0.0.0";
          PORT = "3080";
          MONGO_URI = "mongodb://host.docker.internal:27017/LibreChat";
          ENDPOINTS = "openAI,ollama";
          OLLAMA_BASE_URL = "http://host.docker.internal:11434/v1";
          REFRESH_TOKEN_EXPIRY = toString (1000 * 60 * 60 * 24 * 30); # 30 days
          JWT_SECRET = "librechat-jwt-secret-change-in-production";
          JWT_REFRESH_SECRET = "librechat-refresh-secret-change-in-production";
          ALLOW_REGISTRATION = "true";
        };
        ports = [
          "${toString cfg.port}:3080"
        ];
        log-driver = "journald";
        extraOptions = [
          "--pull=always"
          "--name=librechat"
          "--hostname=librechat"
          "--add-host=host.docker.internal:host-gateway"
        ];
      };
    };

    # Enable MongoDB for LibreChat data storage
    services.mongodb = {
      enable = true;
      package = pkgs.mongodb;
      bind_ip = "0.0.0.0";
    };

    # For MongoDB access from containers
    networking.firewall.trustedInterfaces = [
      "docker0"
    ];

    services.caddy.virtualHosts."librechat.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString cfg.port}
    '';

    # Optional: add to backup
    services.restic.paths = [
      "/var/lib/mongodb"
    ];
  };
}
