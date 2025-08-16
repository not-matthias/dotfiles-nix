# Debug with: journalctl -u docker-lobe-chat.service --no-pager -n 80
{
  config,
  lib,
  domain,
  pkgs,
  ...
}: let
  cfg = config.services.lobe-chat;
in {
  options.services.lobe-chat = {
    enable = lib.mkEnableOption "LobeChat AI conversation interface";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      nextauth-secret = {
        file = ../../../secrets/nextauth-secret.age;
        owner = "root";
        group = "root";
      };
    };

    services.minio.enable = true;
    systemd.services.minio.environment = {
      MINIO_API_CORS_ALLOW_ORIGIN = "https://lobe-chat.desktopnm.duckdns.org";
      MINIO_API_CORS_ALLOW_HEADERS = "Authorization,Content-Type,Content-Length,X-Amz-*";
      MINIO_API_CORS_ALLOW_METHODS = "GET,POST,PUT,DELETE,HEAD,OPTIONS";
      MINIO_API_CORS_EXPOSE_HEADERS = "ETag,x-amz-request-id";
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      enableJIT = true;
      extensions = ps: with ps; [pgvector];
      settings = {
        listen_addresses = lib.mkForce "*";
      };
      authentication = ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local all       all     trust
        # ipv4
        host  all      all     127.0.0.1/32   trust
        host  all      all     172.17.0.0/16  trust
        host  all      all     100.64.0.0/10  trust
        # ipv6
        host all       all     ::1/128        trust
      '';
      ensureDatabases = ["lobe"];
      ensureUsers = [
        {
          name = "lobe";
          ensureDBOwnership = true;
          ensureClauses = {
            superuser = true;
          };
          # ensurePermissions = {
          #   "DATABASE lobe" = "ALL PRIVILEGES";
          # };
        }
      ];
    };

    # services.pgadmin = {
    #   enable = true;
    #   initialEmail = "admin@admin.com";
    #   initialPasswordFile = pkgs.writeText "pgadminpwfile" "admin";
    #   settings = {
    #     DEFAULT_SERVER = "0.0.0.0";
    #     DEFAULT_BINARY_PATHS = {
    #       "pg-16" = "${config.services.postgresql.package}/bin";
    #     };
    #   };
    # };

    virtualisation.oci-containers.containers = {
      "lobe-chat" = {
        image = "docker.io/lobehub/lobe-chat-database:latest";
        environment = {
          "APP_URL" = "https://lobe-chat.${domain}";

          "OLLAMA_PROXY_URL" = "http://host.docker.internal:11434";

          # Postgres related environment variables
          # Required: Postgres database connection string
          "DATABASE_URL" = "postgresql://lobe:lobe@127.0.0.1:5432/lobe";
          # Required: Secret key for encrypting sensitive information. Generate with: openssl rand -base64 32
          "KEY_VAULTS_SECRET" = "Kix2wcUONd4CX51E/ZPAd36BqM4wzJgKjPtz2sGztqQ=";

          # S3/MinIO Configuration
          "S3_ACCESS_KEY_ID" = "minioadmin";
          "S3_SECRET_ACCESS_KEY" = "minioadmin";
          "S3_ENDPOINT" = "https://s3.${domain}";
          "S3_BUCKET" = "lobe";
          "S3_PUBLIC_DOMAIN" = "https://s3.${domain}";
          "S3_ENABLE_PATH_STYLE" = "1";

          # Files/Knowledge Base Configuration
          "DEFAULT_FILES_CONFIG" = "embedding_model=ollama/nomic-embed-text:latest";

          # Authelia SSO Configuration
          "NEXT_AUTH_SECRET" = "Vx/ET7i60bdpaVrxj8NStYAZxF0HmtSzNoDbxIrTR+Q=";
          "NEXT_AUTH_SSO_PROVIDERS" = "authelia";
          "NEXTAUTH_URL" = "https://lobe-chat.${domain}/api/auth";

          "AUTH_AUTHELIA_SECRET" = "insecure_secret";
          "AUTH_AUTHELIA_ID" = "lobe-chat";
          "AUTH_AUTHELIA_ISSUER" = "https://auth.${domain}";
        };
        ports = ["3210:3210/tcp"];
        environmentFiles = [];
        extraOptions = [
          "--pull=always"
          # "--add-host=host.docker.internal:host-gateway"

          # TODO: Can we remove this? -> Fix postgres auth
          "--network=host"
        ];
      };
    };

    services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.mkAfter [
      {
        client_id = "lobe-chat";
        client_name = "LobeChat";
        public = false;
        authorization_policy = "one_factor";
        client_secret = "$pbkdf2-sha512$310000$c8p78n7pUMln0jzvd4aK4Q$JNRBzwAo0ek5qKn50cFzzvE9RXV88h1wJn5KGiHrD0YKtZaR/nCb2CJPOsKaPK0hjf.9yHxzQGZziziccp6Yng"; # The digest of 'insecure_secret'.
        redirect_uris = [
          "https://lobe-chat.${domain}/api/auth/callback/authelia"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
        ];
        userinfo_signed_response_alg = "none";
      }
    ];

    services.caddy.virtualHosts."lobe-chat.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:3210
    '';
    services.caddy.virtualHosts."s3.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:9000
    '';
  };
}
