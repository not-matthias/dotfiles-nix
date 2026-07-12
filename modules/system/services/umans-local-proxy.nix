{
  config,
  lib,
  pkgs,
  flakes,
  ...
}: let
  cfg = config.services.umans-local-proxy;
  package = flakes.umans-local-proxy.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.services.umans-local-proxy = {
    enable = lib.mkEnableOption "UMANS local proxy";
  };

  config = lib.mkIf cfg.enable {
    users.users.umans-local-proxy = {
      isSystemUser = true;
      group = "umans-local-proxy";
      home = "/var/lib/umans-local-proxy";
      createHome = false;
    };

    users.groups.umans-local-proxy = {};

    systemd.tmpfiles.rules = [
      "d /var/lib/umans-local-proxy 0700 umans-local-proxy umans-local-proxy -"
    ];

    age.secrets.umans-local-proxy = {
      file = ../../../secrets/umans-local-proxy.age;
      owner = "umans-local-proxy";
      group = "umans-local-proxy";
      mode = "0400";
    };

    systemd.services.umans-local-proxy = {
      description = "UMANS local proxy";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "simple";
        User = "umans-local-proxy";
        Group = "umans-local-proxy";
        WorkingDirectory = "/var/lib/umans-local-proxy";
        EnvironmentFile = config.age.secrets.umans-local-proxy.path;
        Environment = [
          "HOME=/var/lib/umans-local-proxy"
          "UMANS_PROXY_CONFIG_DIR=/var/lib/umans-local-proxy"
          "UMANS_PROXY_RUNTIME_DIR=/var/lib/umans-local-proxy/runtime"
        ];
        ExecStart = "${lib.getExe package} --listen=127.0.0.1:8084 --start";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
