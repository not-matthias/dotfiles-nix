# https://wiki.nixos.org/wiki/Paperless
{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.paperless;
in {
  config = lib.mkIf cfg.enable {
    services.paperless = {
      port = 11432;
      address = "0.0.0.0";
      settings.PAPERLESS_OCR_LANGUAGE = "deu+eng";
    };

    services.caddy.virtualHosts."paperless.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11432
    '';
  };
}
