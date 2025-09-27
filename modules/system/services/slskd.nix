{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.slskd;
in {
  config = lib.mkIf cfg.enable {
    age.secrets.slskd-env.file = ../../../secrets/slskd-env.age;

    services.slskd = {
      openFirewall = true;
      domain = "slskd.${domain}";
      environmentFile = config.age.secrets.slskd-env.path;
      settings = {
        remote_file_management = true;
        transfers = {
          upload_speed_limit = 1000; # KB/s (1 MB/s upload limit)
        };
      };
    };

    users.groups.slskd-access = {
      members = ["not-matthias" "slskd"];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/slskd/downloads 0775 slskd slskd-access - -"
    ];

    services.caddy.virtualHosts."slskd.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString (cfg.settings.web.port or 5030)}
    '';
  };
}
