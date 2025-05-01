{
  unstable,
  domain,
  ...
}: {
  services.nitter = {
    # enable = true;
    package = unstable.nitter;
    server = {
      # host = "0.0.0.0";
      port = 11000;
      https = false;
    };
  };

  services.caddy.virtualHosts."nitter.${domain}" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11000
    '';
  };
}
