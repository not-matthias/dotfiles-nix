{
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.adguardhome;
in {
  options.services.adguardhome = {
    useDns = lib.mkEnableOption "Use adguard dns server";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.adguardhome = {
        # TODO: https://github.com/ddervisis/dotnix/blob/0ad558ef5bff41a5d3bec296b122ee76981fed80/modules/services/adguardhome.nix#L13
        host = "0.0.0.0"; # Note: don't change to localhost otherwise it won't work (?)
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

      services.caddy.virtualHosts."adguard.${domain}".extraConfig = ''
        encode zstd gzip
        reverse_proxy http://127.0.0.1:11429
      '';
    })

    (lib.mkIf cfg.useDns {
      services.resolved.enable = true;
      networking.nameservers =
        if cfg.useDns
        then lib.mkForce ["100.64.120.57"]
        else [];
    })
  ];
}
