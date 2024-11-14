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

    # TODO: https://github.com/ddervisis/dotnix/blob/0ad558ef5bff41a5d3bec296b122ee76981fed80/modules/services/adguardhome.nix#L13
    services.adguardhome = {
      enable = true;
      host = "0.0.0.0";
      port = 11429;
      mutableSettings = true;
      settings = {
        dns = {
          bind_host = "0.0.0.0";
          bind_hosts = ["0.0.0.0"];
          bootstrap_dns = [
            "1.1.1.1"
            "1.0.0.1"
          ];
          upstream_dns = [
            "1.1.1.1"
            "1.0.0.1"
            "8.8.8.8"
            "8.8.4.4"
          ];
        };
      };
      # TODO: openFirewall?
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

    # References:
    # - https://github.com/jakubgs/nixos-config/blob/7e5e89c43274d58699c1ad9630df5b756af3255e/roles/netdata.nix#L11:w

    # TODO: Only enable when Nvidia GPU is available
    systemd.services.netdata.path = [pkgs.linuxPackages.nvidia_x11];
    services.netdata = {
      enable = true;
      enableAnalyticsReporting = false;
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
          "debug log" = "none";
          "update every" = 5;
          "memory mode" = "ram";
        };
        plugins = {
          "tc" = "no"; # Linux traffic control operations
          "idlejitter" = "no";
          "checks" = "no";
          "apps" = "no";
          "node.d" = "no";
          "python.d" = "no";
          "charts.d" = "no";
          "go.d" = "yes";
          "cgroups" = "yes";
        };

        ml = {"enabled" = "no";};
        "health" = {"enabled" = "no";};
        "statsd" = {"enabled" = "no";};
        "plugin:apps" = {"update every" = 10;};
        "plugin:proc:diskspace" = {
          "update every" = 10;
          "check for new mount points every" = 0;
        };
        "plugin:proc" = {
          "/proc/net/snmp" = "no";
          "/proc/net/snmp6" = "no";
          "/proc/net/ip_vs/stats" = "no";
          "/proc/net/stat/synproxy" = "no";
          "/proc/net/stat/nf_conntrack" = "no";
          "/proc/interrupts" = "no";
          "/proc/softirqs" = "no";
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
      enable = false;
      settings.Port = 11424;
      settings.Address = "0.0.0.0";
      settings.MusicFolder = "/mnt/data/personal/music";
    };
  };
}
