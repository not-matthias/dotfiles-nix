{
  config,
  lib,
  ...
}:
with lib; {
  config = mkIf config.services.postgresql.enable {
    services.postgresql = {
      enableTCPIP = mkDefault true;
      settings = {
        listen_addresses = mkDefault "*";
      };
      authentication = mkAfter ''
        # Allow local connections
        local all all               trust
        host  all all ::1/128       trust
        host  all all 127.0.0.1/32  trust

        # Docker networks
        host  all all 172.17.0.0/16 trust
        host  all all 172.20.0.0/16 trust
        host  all all 172.23.0.0/16 trust
        host  all all 172.16.0.0/12 trust

        # Tailscale
        host  all all 100.64.0.0/10 trust
      '';
    };
  };
}
