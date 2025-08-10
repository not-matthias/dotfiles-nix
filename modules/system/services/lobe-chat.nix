{
  config,
  lib,
  pkgs,
  domain,
  ...
}: let
  cfg = config.services.lobe-chat;
  
  # Configuration variables
  lobePort = "3210";
  casdoorPort = "8000";
  minioPort = "9000";
  minioConsolePort = "9001";
  
  # Database configuration
  lobeDbName = "lobechat";
  postgresPassword = "uWNZugjBqixf8dxC";
  
  # Casdoor authentication
  authCasdoorId = "943e627d79d5dd8a22a1";
  authCasdoorSecret = "6ec24ac304e92e160ef0d0656ecd86de8cb563f1";
  
  # MinIO S3 configuration
  minioRootUser = "Joe";
  minioRootPassword = "Crj1570768";
  minioLobeBucket = "lobe";
  s3AccessKeyId = "dB6Uq9CYZPdWSZouPyEd";
  s3SecretAccessKey = "aPBW8CVULkh8bw1GatlT0GjLihcXHLNwRml4pieS";
  
  # Security keys
  keyVaultSecret = "Kix2wcUONd4CX51E/ZPAd36BqM4wzJgKjPtz2sGztqQ=";
  nextAuthSecret = "NX2kaPE923dt6BL2U8e9oSre5RfoT7hg";
in {
  options.services.lobe-chat = {
    enable = lib.mkEnableOption "LobeChat AI conversation interface with knowledge base support";
  };

  config = lib.mkIf cfg.enable {
    # Create required directories
    systemd.tmpfiles.rules = [
      "d /var/lib/lobe-chat 0755 root root -"
      "d /var/lib/lobe-chat/postgres-data 0755 root root -"
      "d /var/lib/lobe-chat/minio-data 0755 root root -"
    ];

    # Create docker network
    systemd.services.init-lobe-chat-network = {
      description = "Create lobe-chat-network";
      after = ["docker.service"];
      wants = ["docker.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker network ls --format '{{.Name}}' | grep -q '^lobe-network$' || \
        ${pkgs.docker}/bin/docker network create lobe-network
      '';
    };

    virtualisation.oci-containers.containers = {
      # PostgreSQL with PGVector
      "lobe-postgres" = {
        image = "pgvector/pgvector:pg16";
        environment = {
          "POSTGRES_DB" = lobeDbName;
          "POSTGRES_PASSWORD" = postgresPassword;
        };
        volumes = ["/var/lib/lobe-chat/postgres-data:/var/lib/postgresql/data:rw"];
        ports = ["5432:5432/tcp"];
        log-driver = "journald";
        extraOptions = [
          "--health-cmd=pg_isready -U postgres"
          "--health-interval=5s"
          "--health-timeout=5s"
          "--health-retries=5"
          "--network=lobe-network"
          "--network-alias=postgresql"
        ];
      };

      # MinIO S3 storage
      "lobe-minio" = {
        image = "minio/minio:RELEASE.2025-04-22T22-12-26Z";
        environment = {
          "MINIO_ROOT_USER" = minioRootUser;
          "MINIO_ROOT_PASSWORD" = minioRootPassword;
          "MINIO_API_CORS_ALLOW_ORIGIN" = "https://lobe-chat.${domain}";
        };
        volumes = ["/var/lib/lobe-chat/minio-data:/etc/minio/data:rw"];
        ports = ["11439:${minioPort}/tcp" "11440:${minioConsolePort}/tcp"];
        cmd = ["server" "/etc/minio/data" "--address" ":${minioPort}" "--console-address" ":${minioConsolePort}"];
        log-driver = "journald";
        extraOptions = [
          "--network=lobe-network"
          "--network-alias=minio"
        ];
      };

      # Casdoor authentication service
      "lobe-casdoor" = {
        image = "casbin/casdoor";
        environment = {
          "RUNNING_IN_DOCKER" = "true";
          "driverName" = "postgres";
          "dataSourceName" = "user=postgres password=${postgresPassword} host=postgresql port=5432 sslmode=disable dbname=casdoor";
          "origin" = "https://auth.${domain}";
          "runmode" = "dev";
        };
        ports = ["11438:${casdoorPort}/tcp"];
        cmd = ["/bin/sh" "-c" "./server --createDatabase=true"];
        dependsOn = ["lobe-postgres"];
        log-driver = "journald";
        extraOptions = [
          "--network=lobe-network"
          "--network-alias=casdoor"
        ];
      };

      # LobeChat main application
      "lobe-chat" = {
        image = "lobehub/lobe-chat-database";
        environment = {
          # App configuration
          "APP_URL" = "https://lobe-chat.${domain}";
          
          # Authentication - Use anonymous access for now
          "NEXT_AUTH_SSO_PROVIDERS" = "";
          "AUTH_ANONYMOUS_ACCESS" = "true";
          "KEY_VAULTS_SECRET" = keyVaultSecret;
          "NEXT_AUTH_SECRET" = nextAuthSecret;
          
          # Database
          "DATABASE_URL" = "postgresql://postgres:${postgresPassword}@postgresql:5432/${lobeDbName}";
          
          # S3 Storage
          "S3_ENDPOINT" = "http://minio:${minioPort}";
          "S3_BUCKET" = minioLobeBucket;
          "S3_PUBLIC_DOMAIN" = "https://minio.${domain}";
          "S3_ACCESS_KEY_ID" = s3AccessKeyId;
          "S3_SECRET_ACCESS_KEY" = s3SecretAccessKey;
          "S3_ENABLE_PATH_STYLE" = "1";
          "LLM_VISION_IMAGE_USE_BASE64" = "1";
          
          # Other configurations
          "OLLAMA_PROXY_URL" = "http://host.docker.internal:11434";
        };
        ports = ["11433:${lobePort}/tcp"];
        dependsOn = ["lobe-postgres" "lobe-minio"];
        log-driver = "journald";
        extraOptions = [
          "--add-host=host.docker.internal:host-gateway"
          "--network=lobe-network"
          "--network-alias=lobe"
        ];
      };
    };

    # Caddy reverse proxy configuration
    services.caddy.virtualHosts = {
      # Main LobeChat application
      "lobe-chat.${domain}" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy http://127.0.0.1:11433
        '';
      };
      
      # Casdoor authentication service
      "auth.${domain}" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy http://127.0.0.1:11438
          
          # Allow Casdoor OAuth2 well-known endpoints
          handle_path /.well-known/* {
            reverse_proxy http://127.0.0.1:11438
          }
        '';
      };
      
      # MinIO S3 API
      "minio.${domain}" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy http://127.0.0.1:11439
        '';
      };
      
      # Optional: MinIO admin interface
      "minio-ui.${domain}" = {
        extraConfig = ''
          encode zstd gzip
          reverse_proxy http://127.0.0.1:11440
        '';
      };
    };

    # services.restic.paths = [
    #   "/var/lib/lobe-chat/"
    # ];
  };
}
