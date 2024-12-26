{
  lib,
  config,
  ...
}: let
  cfg = config.services.traggo;
in {
  options.services.traggo = {
    enable = lib.mkEnableOption "Enable Traggo";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.arion.backend = "docker";

    virtualisation.arion.projects.traggo.settings.services = {
      traggo.service = {
        image = "traggo/server:latest";
        environment = {
          "TRAGGO_DEFAULT_USER_NAME" = "admin";
          "TRAGGO_DEFAULT_USER_PASS" = "admin";
        };
        volumes = [
          "/var/lib/traggo/data:/opt/traggo/data:rw"
        ];
        ports = [
          "3030:3030/tcp"
        ];
      };
    };

    services.restic.backups.nas.paths = ["/var/lib/traggo"];
  };
}
