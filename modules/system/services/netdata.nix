{
  config,
  lib,
  domain,
  unstable,
  pkgs,
  ...
}: let
  cfg = config.services.netdata;
in {
  config = lib.mkIf cfg.enable {
    # Only enable when Nvidia GPU is available
    systemd.services.netdata.path = [pkgs.linuxPackages.nvidia_x11];

    services.netdata = {
      enableAnalyticsReporting = false;
      package = unstable.netdata.override {
        withCloudUi = true;
      };
      # TODO: Only set when nvidia is used
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

        ml = {"enabled" = "true";};
        health = {"enabled" = "no";};
        statsd = {"enabled" = "no";};
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

    services.caddy.virtualHosts."netdata.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:11427
    '';
  };
}
