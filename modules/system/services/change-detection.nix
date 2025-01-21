{
  config,
  lib,
  ...
}: let
  cfg = config.services.change-detection;
in {
  options.services.change-detection = {
    enable = lib.mkEnableOption "Enable Change Detection";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      "playwright-chrome" = {
        image = "docker.io/browserless/chrome";
      };

      "change-detection" = {
        image = "docker.io/dgtlmoon/changedetection.io";
        volumes = ["/var/lib/change-detection:/datastore"];
        dependsOn = ["playwright-chrome"];
        environment = {
          PLAYWRIGHT_DRIVER_URL = "ws://playwright-chrome:3000/";
        };
        ports = [
          "5000:5000"
        ];
      };
    };
  };
}
