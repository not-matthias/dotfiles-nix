{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.maloja;
in {
  options.services.maloja = {
    enable = lib.mkEnableOption "Enable maloja";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      maloja = {
        # https://hub.docker.com/r/krateng/maloja/tags
        image = "krateng/maloja:3.2.4";
        environment = {
          MALOJA_DATA_DIRECTORY = "/mljdata";
          MALOJA_FORCE_PASSWORD = "admin"; # FIXME: Change this
        };
        ports = [
          "42010:42010/tcp"
        ];
        volumes = [
          "/var/lib/maloja:/mljdata"
        ];
      };
    };

    services.caddy.virtualHosts."maloja.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:42010
    '';

    services.restic.paths = ["/var/lib/maloja"];
  };
}
