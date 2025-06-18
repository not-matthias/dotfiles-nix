{
  unstable,
  domain,
  config,
  lib,
  ...
}: let
  cfg = config.services.karakeep;
in {
  config = lib.mkIf cfg.enable {
    services.karakeep = {
      package = unstable.karakeep;
      extraEnvironment = {
        PORT = "9999";

        # TODO: Setup AI tagging
        # https://docs.karakeep.app/configuration/#inference-configs-for-automatic-tagging

        CRAWLER_VIDEO_DOWNLOAD = "true";
        CRAWLER_VIDEO_DOWNLOAD_MAX_SIZE = "-1";
      };
      browser.enable = true;
      meilisearch.enable = true;
    };

    services.meilisearch.package = unstable.meilisearch;

    services.caddy.virtualHosts."links.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:9999
    '';
  };
}
