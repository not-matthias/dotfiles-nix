{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.stump;
in {
  options.services.stump = {
    enable = lib.mkEnableOption "Enable stump";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      stump = {
        image = "docker.io/aaronleopold/stump:latest";
        environment = {
          PUID = "1000";
          PGID = "1000";

          # https://www.stumpapp.dev/guides/configuration/server-options
          ENABLE_UPLOAD = "true";
          STUMP_PORT = "10801";
        };
        ports = [
          "10801:10801/tcp"
        ];
        volumes = [
          "/var/lib/memos/config:/config"
          "/mnt/data/personal/books:/data"
        ];
      };
    };

    services.caddy.virtualHosts."books.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:10801
    '';
  };
}
