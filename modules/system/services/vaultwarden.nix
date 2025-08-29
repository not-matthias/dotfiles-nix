{
  config,
  lib,
  domain,
  ...
}: let
  cfg = config.services.vaultwarden;
in {
  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      config = {
        DOMAIN = "https://vault.${domain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 11438;
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = false;
        SHOW_PASSWORD_HINT = false;
        WEB_VAULT_ENABLED = true;
      };
    };

    services.caddy.virtualHosts."vault.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11438
    '';

    services.restic.paths = ["/var/lib/bitwarden_rs"];
  };
}
