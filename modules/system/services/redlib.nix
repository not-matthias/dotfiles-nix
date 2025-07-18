{
  unstable,
  domain,
  ...
}: {
  services.redlib = {
    package = unstable.redlib;
    address = "127.0.0.1";
    port = 10999;
    settings = {
      # Basic configuration
      REDLIB_SFW_ONLY = false;
      REDLIB_USE_HLS = true;
      REDLIB_HIDE_HLS_NOTIFICATION = false;

      # Theming
      REDLIB_DEFAULT_THEME = "dark";
      REDLIB_DEFAULT_FRONT_PAGE = "default";
      REDLIB_DEFAULT_LAYOUT = "card";
      REDLIB_DEFAULT_WIDE = "off";

      # Features
      REDLIB_DEFAULT_POST_SORT = "hot";
      REDLIB_DEFAULT_COMMENT_SORT = "confidence";
      REDLIB_DEFAULT_SHOW_NSFW = "off";
      REDLIB_DEFAULT_BLUR_NSFW = "on";
      REDLIB_DEFAULT_USE_HLS = "on";
      REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION = "off";
      REDLIB_DEFAULT_AUTOPLAY_VIDEOS = "off";
    };
  };

  services.caddy.virtualHosts."redlib.${domain}" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:10999
    '';
  };
}
