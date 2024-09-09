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
      LISTEN_ADDR = "0.0.0.0:4242";
      CLEANUP_FREQUENCY = "48";
    };
  };

  services.rss-bridge = {
    enable = true;
    config.system.enabled_bridges = ["*"];
  };
}
