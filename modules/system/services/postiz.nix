{
  config,
  lib,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.postiz;
in {
  options.services.postiz = {
    enable = lib.mkEnableOption "Postiz social media management platform";
  };

  config = lib.mkIf cfg.enable {
    # Create required directories
    systemd.tmpfiles.rules = [
      "d /var/lib/postiz 0755 root root -"
      "d /var/lib/postiz/config 0755 root root -"
      "d /var/lib/postiz/uploads 0755 root root -"
      "d /var/lib/postiz/postgres-data 0755 root root -"
      "d /var/lib/postiz/redis-data 0755 root root -"
    ];

    # Create network for containers
    systemd.services.init-postiz-network = {
      description = "Create postiz-network";
      after = ["podman.service"];
      wants = ["podman.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.podman}/bin/podman network exists postiz-network || \
        ${pkgs.podman}/bin/podman network create postiz-network
      '';
    };

    virtualisation.oci-containers.containers = {
      "postiz" = {
        image = "ghcr.io/gitroomhq/postiz-app:latest";
        environment = {
          "BACKEND_INTERNAL_URL" = "http://localhost:3000";
          "DATABASE_URL" = "postgresql://postiz-user:postiz-password@postiz-postgres:5432/postiz-db-local";
          "DISABLE_REGISTRATION" = "true";
          "FRONTEND_URL" = "https://postiz.${domain}";
          "IS_GENERAL" = "true";
          "JWT_SECRET" = "wrgSz71HZmQBUfcsuCTxTe3xIIo$VK0n";
          "MAIN_URL" = "https://postiz.${domain}";
          "NEXT_PUBLIC_BACKEND_URL" = "https://postiz.${domain}/api";
          "NEXT_PUBLIC_UPLOAD_DIRECTORY" = "/uploads";
          "NTBA_FIX_350" = "1";
          "REDIS_URL" = "redis://postiz-redis:6379";
          "STORAGE_PROVIDER" = "local";
          "UPLOAD_DIRECTORY" = "/uploads";
        };
        volumes = [
          "/var/lib/postiz/config:/config:rw"
          "/var/lib/postiz/uploads:/uploads:rw"
        ];
        ports = ["11436:5000/tcp"];
        dependsOn = ["postiz-postgres" "postiz-redis"];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=postiz"
          "--network=postiz-network"
        ];
      };

      "postiz-postgres" = {
        image = "postgres:17-alpine";
        environment = {
          "POSTGRES_DB" = "postiz-db-local";
          "POSTGRES_PASSWORD" = "postiz-password";
          "POSTGRES_USER" = "postiz-user";
        };
        volumes = ["/var/lib/postiz/postgres-data:/var/lib/postgresql/data:rw"];
        log-driver = "journald";
        extraOptions = [
          "--health-cmd=pg_isready -U postiz-user -d postiz-db-local"
          "--health-interval=10s"
          "--health-retries=3"
          "--health-timeout=3s"
          "--network-alias=postiz-postgres"
          "--network=postiz-network"
        ];
      };

      "postiz-redis" = {
        image = "redis:7.2";
        volumes = ["/var/lib/postiz/redis-data:/data:rw"];
        log-driver = "journald";
        extraOptions = [
          "--health-cmd=redis-cli ping"
          "--health-interval=10s"
          "--health-retries=3"
          "--health-timeout=3s"
          "--network-alias=postiz-redis"
          "--network=postiz-network"
        ];
      };
    };

    services.caddy.virtualHosts."postiz.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11436
    '';

    # services.restic.paths = [
    #   "/var/lib/postiz/"
    # ];
  };
}
