# Created the session key using this:
# https://gist.github.com/cmj/998f59680e3549e7f181057074eccaa3
# https://gist.github.com/doichev-kostia/bef41b496397bb49ebcdf7f53a49fc45
{
  unstable,
  domain,
  config,
  ...
}: {
  services.nitter = {
    package = unstable.nitter;
    redisCreateLocally = true;
    sessionsFile = config.age.secrets.nitter-session.path;
    server = {
      address = "127.0.0.1";
      port = 11000;
      https = false;
    };
    preferences = {
      autoplayGifs = false;
      bidiSupport = false;
    };
    config = {
      enableRSS = true;
      enableDebug = false;
      base64Media = false;
      tokenCount = 10;
    };
    cache = {
      listMinutes = 240;
      rssMinutes = 10;
      redisConnections = 20;
      redisMaxConnections = 30;
      redisHost = "localhost";
      redisPort = 6379;
    };
  };

  age.secrets.nitter-session.file = ../../../secrets/nitter-session.age;

  services.caddy.virtualHosts."nitter.${domain}" = {
    extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11000
    '';
  };
}
