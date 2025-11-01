{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.wakapi;
in {
  options.services.wakapi = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8004;
      description = "Port for Wakapi application to listen on internally";
    };
  };

  config = lib.mkIf cfg.enable {
    services.wakapi = {
      passwordSaltFile = config.age.secrets.wakapi-salt.path;
      settings = {
        server = {
          listen_ipv4 = "127.0.0.1";
          listen_ipv6 = "-"; # Disable IPv6
          port = cfg.port;
          public_url = "https://wakapi.${domain}";
        };
        db.dialect = "sqlite3";
        app = {
          aggregation_time = "0 15 2 * * *";
          report_time_weekly = "0 0 18 * * 5";
          data_cleanup_time = "0 0 6 * * 0";
          import_enabled = true;
          leaderboard_enabled = false;
        };
      };
    };

    age.secrets.wakapi-salt = {
      file = ../../../secrets/wakapi-salt.age;
      owner = "wakapi";
      group = "wakapi";
      mode = "0400";
    };

    services.restic.paths = ["/var/lib/wakapi"];

    services.caddy.virtualHosts."wakapi.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString cfg.port}
    '';
  };
}
