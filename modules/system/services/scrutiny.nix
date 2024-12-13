{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.scrutiny;
in {
  config = lib.mkIf cfg.enable {
    services.scrutiny = {
      collector.enable = true;
      settings.web.listen.port = 11428;
      settings.notify.urls = [
        "ntfy://ntfy.sh/desktop-zfs"
      ];
    };

    services.caddy.virtualHosts."scrutiny.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://localhost:11428
    '';
  };
}
