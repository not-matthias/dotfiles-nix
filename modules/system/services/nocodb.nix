{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.nocodb;
in {
  options.services.nocodb = {
    enable = lib.mkEnableOption "Enable the NocoDB service";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      nocodb = {
        image = "nocodb/nocodb:latest";
        ports = ["8080:8080"];
        volumes = ["/var/lib/nocodb:/usr/app/data"];
      };
    };

    services.caddy.virtualHosts."nocodb.${domain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:8080
    '';

    services.restic.paths = ["/var/lib/nocodb"];
  };
}
