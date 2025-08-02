# References:
# - https://github.com/starr-dusT/dotfiles/blob/500e615f4297142000160b22dc071de60ec908f9/provision/hosts/torus/rss.nix#L17
{
  pkgs,
  lib,
  config,
  domain,
  ...
}: let
  cfg = config.services.miniflux;
in {
  # Can be enabled with `services.miniflux.enable = true;`
  config = lib.mkIf cfg.enable {
    services.miniflux = {
      # adminCredentialsFile = "/etc/miniflux.env";
      # Set initial admin user/password
      adminCredentialsFile = pkgs.writeText "cred" ''
        ADMIN_USERNAME=miniflux
        ADMIN_PASSWORD=miniflux
      '';
      config = {
        LISTEN_ADDR = "0.0.0.0:4242";
        CLEANUP_FREQUENCY = "48";
      };
    };

    # TODO: use and set port
    # services.rss-bridge = {
    #   enable = true;
    #   config.system.enabled_bridges = ["*"];
    # };

    services.caddy.virtualHosts."rss.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:4242
    '';

    services.restic.paths = ["/var/lib/miniflux"];
  };
}
