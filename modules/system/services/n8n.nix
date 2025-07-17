{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.n8n;
in {
  config = lib.mkIf cfg.enable {
    services.n8n = {
      webhookUrl = "https://n8n.${domain}";
      settings = {
        # TODO
      };
    };

    services.caddy.virtualHosts."n8n.${domain}" = {
      extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:5678
      '';
    };

    services.restic.paths = ["/var/lib/n8n"];
  };
}
