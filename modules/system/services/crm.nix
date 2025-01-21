{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.crm;
in {
  options.services.crm = {
    enable = lib.mkEnableOption "Enable CRM";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      crm = {
        image = "ghcr.io/not-matthias/personal-crm:main";
        ports = [
          "3000:3000/tcp"
        ];
      };
    };

    services.caddy = {
      virtualHosts."crm.${domain}".extraConfig = ''
        encode zstd gzip
        reverse_proxy http://localhost:3000
      '';
    };
  };
}
