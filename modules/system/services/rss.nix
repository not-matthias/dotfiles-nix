# References:
# - https://github.com/starr-dusT/dotfiles/blob/500e615f4297142000160b22dc071de60ec908f9/provision/hosts/torus/rss.nix#L17
{pkgs, ...}: {
  # Add dns record 'miniflux' to /etc/hosts
  #

  services.miniflux = {
    enable = true;
    # adminCredentialsFile = "/etc/miniflux.env";
    # Set initial admin user/password
    adminCredentialsFile = pkgs.writeText "cred" ''
      ADMIN_USERNAME=miniflux
      ADMIN_PASSWORD=miniflux
    '';
    config = {
      LISTEN_ADDR = "127.0.0.1:4242";
      CLEANUP_FREQUENCY = "48";
      YOUTUBE_EMBED_URL_OVERRIDE = "https://";
    };
  };

  services.rss-bridge = {
    enable = true;
    config.system.enabled_bridges = ["*"];
  };
}
