{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.watchyourlan;
in {
  options.services.watchyourlan = {
    enable = lib.mkEnableOption "Enable WatchYourLAN";
    ifaces = lib.mkOption {
      type = lib.types.str;
      description = "The interfaces to listen on";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      watchyourlan = {
        volumes = ["/var/lib/watchyourlan:/data/WatchYourLAN"];
        environment = {
          IFACES = cfg.ifaces;
          TZ = "Europe/Vienna";
        };
        image = "aceberg/watchyourlan";
        extraOptions = [
          "--network=host"
        ];
      };
    };

    services.caddy.virtualHosts."lan.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:8840
    '';
  };
}
