{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.authelia;
in {
  options.services.authelia = {
    enable = lib.mkEnableOption "Authelia authentication and authorization server";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      authelia-jwt-secret = {
        file = ../../../secrets/authelia-jwt-secret.age;
        owner = "authelia-main";
        group = "authelia-main";
      };
      authelia-session-secret = {
        file = ../../../secrets/authelia-session-secret.age;
        owner = "authelia-main";
        group = "authelia-main";
      };
      authelia-storage-encryption-key = {
        file = ../../../secrets/authelia-storage-encryption-key.age;
        owner = "authelia-main";
        group = "authelia-main";
      };
      authelia-oidc-secret = {
        file = ../../../secrets/authelia-oidc-secret.age;
        owner = "authelia-main";
        group = "authelia-main";
      };
      authelia-oidc-hmac-secret = {
        file = ../../../secrets/authelia-oidc-hmac-secret.age;
        owner = "authelia-main";
        group = "authelia-main";
      };
    };

    services.authelia.instances.main = {
      enable = true;
      secrets = {
        jwtSecretFile = config.age.secrets.authelia-jwt-secret.path;
        storageEncryptionKeyFile = config.age.secrets.authelia-storage-encryption-key.path;
        manual = false;
      };
      environmentVariables = {
        AUTHELIA_SESSION_SECRET_FILE = config.age.secrets.authelia-session-secret.path;
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = config.age.secrets.authelia-oidc-hmac-secret.path;
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = config.age.secrets.authelia-oidc-secret.path;
        AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE = config.age.secrets.authelia-jwt-secret.path;
      };

      settings = {
        theme = "dark";
        default_2fa_method = "totp";
        log = {
          level = "debug";
          format = "text";
          keep_stdout = true;
        };
        authentication_backend = {
          file = {
            path = "/etc/authelia/users.yml";
          };
        };
        access_control.default_policy = "one_factor";
        session = {
          cookies = [
            {
              domain = domain;
              authelia_url = "https://auth.${domain}";
            }
          ];
          expiration = "12h";
          inactivity = "45m";
        };

        identity_providers.oidc = {
          lifespans = {
            access_token = "1h";
            authorize_code = "1m";
            id_token = "1h";
            refresh_token = "90m";
          };
          enable_client_debug_messages = false;
          minimum_parameter_entropy = 8;
          clients = [];
        };
        storage = {
          local = {
            path = "/var/lib/authelia-main/db.sqlite3";
          };
        };

        notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
      };
    };

    # Users database file - managed outside the service
    environment.etc."authelia/users.yml" = {
      text = ''
        users:
          not-matthias:
            displayname: "Matthias"
            password: "$argon2id$v=19$m=65536,t=3,p=4$OcptMAIy/x9AKgUujdmeRw$QTbgbwhSPdX9hzs8kOcCXtZyyTbp5utH+QW0jZ5Lj9U"
            email: not-matthias@${domain}
            groups:
              - admins
              - dev

          admin:
            displayname: "Admin User"
            # Generate password hash with: nix shell nixpkgs#authelia --command authelia crypto hash generate argon2 --password "yourpassword"
            password: "$argon2id$v=19$m=65536,t=3,p=4$OcptMAIy/x9AKgUujdmeRw$QTbgbwhSPdX9hzs8kOcCXtZyyTbp5utH+QW0jZ5Lj9U"
            email: admin@${domain}
            groups:
              - admins
              - dev
      '';
      mode = "0644";
    };

    services.caddy.virtualHosts."auth.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:9091
    '';
  };
}
