{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.adguard;
in {
  options.services.adguard = {
    enable = lib.mkEnableOption "Enable adguard server";
    useDns = lib.mkEnableOption "Use adguard dns server";
  };

  config = lib.mkIf cfg.useDns or cfg.enable {
    # TODO: https://github.com/ddervisis/dotnix/blob/0ad558ef5bff41a5d3bec296b122ee76981fed80/modules/services/adguardhome.nix#L13
    services.adguardhome = {
      enable = cfg.enable;
      host = "127.0.0.1";
      port = 11429;
      mutableSettings = true;
      settings = {
        dns = {
          bootstrap_dns = [
            "1.1.1.1"
            "1.0.0.1"
          ];
          upstream_dns = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
      };
    };

    # DNS Configuration
    #
    # services.resolved.enable = true;
    networking.nameservers =
      if cfg.useDns
      then lib.mkForce ["100.64.120.57"]
      else [];

    services.caddy.virtualHosts."adguard.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11429
    '';
  };
}
