{
  config,
  domain,
  lib,
  ...
}: let
  cfg = config.services.kaneo;
  port = 5173;
in {
  options.services.kaneo = {
    enable = lib.mkEnableOption "Kaneo project management";

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/usekaneo/kaneo:2.22.0";
      description = "Kaneo container image to run.";
    };

    authSecretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        File containing AUTH_SECRET for Kaneo. If unset, Kaneo generates a
        temporary secret on each container start.
      '';
    };
    publicUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://kaneo.${domain}";
      description = "Public URL used by the Kaneo client and API";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      ensureDatabases = ["kaneo"];
      ensureUsers = [
        {
          name = "kaneo";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/kaneo 0750 1001 1001 -"
    ];

    virtualisation.oci-containers.containers.kaneo = {
      image = cfg.image;
      environment = {
        DATABASE_URL = "postgresql://kaneo@127.0.0.1:5432/kaneo";
        KANEO_API_URL = "${cfg.publicUrl}/api";
        KANEO_CLIENT_URL = cfg.publicUrl;
      };
      environmentFiles = lib.optional (cfg.authSecretFile != null) cfg.authSecretFile;
      volumes = [
        "/var/lib/kaneo:/app/apps/api/data:rw"
      ];
      extraOptions = [
        "--network=host"
      ];
      log-driver = "journald";
    };

    services.caddy.virtualHosts."kaneo.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString port}
    '';

    services.restic.paths = ["/var/lib/kaneo"];
  };
}
