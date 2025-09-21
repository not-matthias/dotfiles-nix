{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.multi-scrobbler;
in {
  options.services.multi-scrobbler = {
    enable = lib.mkEnableOption "Enable multi-scrobbler";
  };

  config = lib.mkIf cfg.enable {
    age.secrets = {
      maloja-api-key = {
        file = ../../../secrets/maloja-api-key.age;
        owner = "root";
        group = "root";
      };
      spotify-client-id = {
        file = ../../../secrets/spotify-client-id.age;
        owner = "root";
        group = "root";
      };
      spotify-client-secret = {
        file = ../../../secrets/spotify-client-secret.age;
        owner = "root";
        group = "root";
      };
    };
    virtualisation.oci-containers.containers = {
      multi-scrobbler = {
        # https://hub.docker.com/r/foxxmd/multi-scrobbler
        image = "foxxmd/multi-scrobbler:latest";
        environment = {
          TZ = "Etc/GMT";
          MALOJA_URL = "http://desktop.local:42010";
          SPOTIFY_REDIRECT_URI = "http://127.0.0.1:9078/callback";
          WS_ENABLE = "true";
        };
        environmentFiles = [
          config.age.secrets.maloja-api-key.path
          config.age.secrets.spotify-client-id.path
          config.age.secrets.spotify-client-secret.path
        ];
        ports = [
          "9078:9078/tcp"
        ];
        volumes = [
          "/var/lib/multi-scrobbler:/config"
        ];
      };
    };

    services.caddy.virtualHosts."multi-scrobbler.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:9078
    '';

    # Ensure the config directory exists with proper permissions
    systemd.tmpfiles.rules = [
      "d /var/lib/multi-scrobbler 0755 root root -"
    ];
  };
}
