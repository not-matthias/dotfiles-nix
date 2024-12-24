{
  lib,
  config,
  ...
}: let
  # Define ports map
  #
  # PORTS = {
  # TODO
  # };
  cfg = config.services.self-hosted;
in {
  options.services.self-hosted = {
    enable = lib.mkEnableOption "Collection of self hosted services";
  };

  config = lib.mkIf cfg.enable {
    services.outline = {
      enable = false;
      port = 11431;
      storage.storageType = "local";
      forceHttps = false;
    };

    #environment.systemPackages = [
    #  pkgs.jellyfin
    #  pkgs.jellyfin-web
    #  pkgs.jellyfin-ffmpeg
    #];
    services.jellyfin = {
      enable = false;
      # openFirewall
      #port = 11429;
    };
    #services.jellyseerr = {
    #  enable = true;
    #  port = 5055;
    #};

    # TODO: Works with free version as well
    # services.ntfy-sh = {
    #   enable = true;
    #   # https://docs.ntfy.sh/config/#config-options
    #   settings = {
    #     listen-http = "127.0.0.1:2586";
    #     base-url = "http://localhost";
    #   };
    # };
  };
}
