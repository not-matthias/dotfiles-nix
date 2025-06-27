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
      extraEnvironment = rec {
        PORT = "9999";

        # TODO: Setup AI tagging
        # https://docs.karakeep.app/configuration/#inference-configs-for-automatic-tagging
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
        OLLAMA_KEEP_ALIVE = "5m";

        CRAWLER_FULL_PAGE_SCREENSHOT = "true";
        CRAWLER_FULL_PAGE_ARCHIVE = "true";

        INFERENCE_CONTEXT_LENGTH = "8192";
        INFERENCE_EMBEDDING_MODEL = "nomic-embed-text";
        INFERENCE_IMAGE_MODEL = "gemma3:4b-it-qat";
        INFERENCE_TEXT_MODEL = "qwen3:30b-a3b";
        INFERENCE_JOB_TIMEOUT_SEC = "600";
        INFERENCE_ENABLE_AUTO_SUMMARIZATION = "false";
        INFERENCE_ENABLE_AUTO_TAGGING = "true";
        INFERENCE_LANG = "english";

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
