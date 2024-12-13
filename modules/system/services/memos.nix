{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.memos;
in {
  options.services.memos = {
    enable = lib.mkEnableOption "Enable memos";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      memos = {
        image = "docker.io/neosmemo/memos:stable";
        environment = {
          MEMOS_METRIC = "false";
        };
        ports = [
          "5230:5230/tcp"
        ];
        volumes = [
          "/var/lib/memos:/var/opt/memos"
        ];
      };
    };

    # See: https://www.usememos.com/docs/install/https
    services.caddy = {
      virtualHosts."memos.${domain}".extraConfig = ''
        reverse_proxy http://localhost:5230

        log {
            format console
            output file /logs/memos.log {
            roll_size 10mb
            roll_keep 20
            roll_keep_for 7d
            }
        }

        encode {
            zstd
            gzip
            minimum_length 1024
        }
      '';
    };
  };
}
