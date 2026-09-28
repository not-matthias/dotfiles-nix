{
  config,
  domain,
  lib,
  user,
  ...
}: let
  cfg = config.services.taskwarrior-sync;
in {
  options.services.taskwarrior-sync = {
    enable = lib.mkEnableOption "Taskchampion sync server and todo proxy";
    client.enable = lib.mkEnableOption "Taskchampion sync client secret";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable || cfg.client.enable) {
      age.secrets.taskchampion-sync = {
        file = ../../../secrets/taskchampion-sync.age;
        owner = user;
      };
    })
    (lib.mkIf cfg.enable {
      services.taskchampion-sync-server = {
        enable = true;
        host = "0.0.0.0";
        port = 10222;
        allowClientIds = ["7af28379-c8aa-468e-8b9a-949021609eb7"];
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [10222];
      networking.hosts."127.0.0.1" = ["todo.${domain}"];

      services.caddy.virtualHosts."todo.${domain}" = {
        listenAddresses = ["127.0.0.1"];
        extraConfig = ''
          tls {
            dns duckdns {env.DUCKDNS_TOKEN}
          }
          encode zstd gzip
          reverse_proxy http://127.0.0.1:3000
        '';
      };
    })
  ];
}
