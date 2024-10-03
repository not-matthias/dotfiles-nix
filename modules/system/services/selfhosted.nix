{
  lib,
  config,
  unstable,
  pkgs,
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
    services.paperless = {
      enable = false;
      port = 11432;
    };

    services.outline = {
      enable = false;
      port = 11431;
      storage.storageType = "local";
      forceHttps = false;
    };

    services.gitea = {
      enable = false;
      settings.server.HTTP_HOST = "0.0.0.0";
      settings.server.HTTP_PORT = 11430;
    };

    services.adguardhome = {
      enable = false;
      host = "0.0.0.0";
      port = 11429;
      mutableSettings = true;
      # TODO: openFirewall?
    };

    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];
    services.jellyfin = {
      enable = true;
      # openFirewall
      #port = 11429;
    };
    #services.jellyseerr = {
    #  enable = true;
    #  port = 5055;
    #};

    services.home-assistant = {
      enable = false;
      config.http.server_port = 8123;
    };

    # Keep track of SMART data
    services.scrutiny = {
      enable = true;
      collector.enable = true;
      settings.web.listen.port = 11428;
      settings.notify.urls = [
        "ntfy://ntfy.sh/desktop-zfs"
      ];
    };

    # Don't need this because of scrutiny
    # services.smartd = {
    #   enable = true;
    #   autodetect = true;
    #   extraOptions = ["--interval=7200"];
    #   notifications.test = true;
    #   notifications.wall.enable = true;
    #   notifications.x11.enable = true;
    # };

    systemd.services.netdata.path = [pkgs.linuxPackages.nvidia_x11];
    services.netdata = {
      enable = true;
      package = unstable.netdata.override {
        withCloudUi = true;
      };
      configDir."python.d.conf" = pkgs.writeText "python.d.conf" ''
        nvidia_smi: yes
      '';
      config = {
        global = {
          "default port" = "11427";
          "bind to" = "*";
          # 7 days
          "history" = "604800";
          "error log" = "syslog";
          "debug log" = "syslog";
        };
      };
    };

    services.firefly-iii = {
      enable = false;
      # port = 11426;
    };

    services.ntopng = {
      enable = false;
      httpPort = 11425;
    };

    # TODO: Works with free version as well
    # services.ntfy-sh = {
    #   enable = true;
    #   # https://docs.ntfy.sh/config/#config-options
    #   settings = {
    #     listen-http = "127.0.0.1:2586";
    #     base-url = "http://localhost";
    #   };
    # };

    services.navidrome = {
      enable = true;
      settings.Port = 11424;
      settings.Address = "0.0.0.0";
      settings.MusicFolder = "/mnt/data/personal/music";
    };
  };
}
