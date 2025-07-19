{
  unstable,
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.ntfy-sh;
in {
  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      package = unstable.ntfy-sh;
      settings = {
        base-url = "https://ntfy.${domain}";
        listen-http = ":1080";
      };
    };

    services.caddy.virtualHosts."ntfy.${domain}".extraConfig = ''
      reverse_proxy http://127.0.0.1:1080
    '';
  };
}
