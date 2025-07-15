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
      settings = {
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_ALLOWED_HOSTS = "paperless.${domain},localhost,127.0.0.1";
        PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.${domain}";

        PAPERLESS_OCR_USER_ARGS = {
          # Use lossless optimizer
          # See: https://ocrmypdf.readthedocs.io/en/latest/optimizer.html
          #
          optimize = 1;
          pdfa_image_compression = "lossless";

          # Paperless refuses to handle signed PDFs (i.e. Docusign) by default
          # because its OCR would invalidate the signature. Since paperless keeps
          # originals however, this is of no relevance to me.
          # See: https://github.com/paperless-ngx/paperless-ngx/discussions/4830
          #
          invalidate_digital_signatures = true;
        };
      };
    };

    services.caddy.virtualHosts."paperless.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11432
    '';

    services.restic.backups.nas.paths = ["/var/lib/paperless"];
  };
}
