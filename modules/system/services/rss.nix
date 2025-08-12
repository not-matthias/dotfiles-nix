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

        OAUTH2_PROVIDER = "oidc";
        OAUTH2_CLIENT_ID = "miniflux";
        OAUTH2_CLIENT_SECRET = "insecure_secret";
        OAUTH2_REDIRECT_URL = "https://rss.${domain}/oauth2/oidc/callback";
        OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${domain}";
        OAUTH2_USER_CREATION = 1;
        DISABLE_LOCAL_AUTH = 1;
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

    services.authelia.instances.main.settings.identity_providers.oidc.clients = lib.mkAfter [
      {
        client_id = "miniflux";
        client_name = "Miniflux RSS Reader";
        public = false;
        authorization_policy = "one_factor";
        client_secret = "$pbkdf2-sha512$310000$c8p78n7pUMln0jzvd4aK4Q$JNRBzwAo0ek5qKn50cFzzvE9RXV88h1wJn5KGiHrD0YKtZaR/nCb2CJPOsKaPK0hjf.9yHxzQGZziziccp6Yng"; # The digest of 'insecure_secret'.
        redirect_uris = [
          "https://rss.${domain}/oauth2/oidc/callback"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
        ];
        userinfo_signed_response_alg = "none";
      }
    ];

    services.restic.paths = ["/var/lib/miniflux"];
  };
}
