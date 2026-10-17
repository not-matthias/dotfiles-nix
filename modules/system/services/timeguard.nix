{
  config,
  lib,
  flakes,
  ...
}: {
  imports = [flakes.timeguard.nixosModules.default];

  environment = lib.mkIf config.services.timeguard.enable {
    systemPackages = [config.services.timeguard.package];
  };

  age.secrets.timeguard-rules = {
    file = ../../../secrets/timeguard-rules.age;
    owner = "root";
    group = "timeguard-proxy";
    mode = "0440";
  };

  services.timeguard.rulesFile = config.age.secrets.timeguard-rules.path;

  systemd = lib.mkIf config.services.timeguard.enable {
    services.timeguard.unitConfig.RefuseManualStop = true;
    targets.timeguard-guard = {
      description = "Keep Timeguard running";
      wantedBy = ["multi-user.target"];
      unitConfig = {
        Upholds = "timeguard.service";
        RefuseManualStop = true;
      };
    };
  };
}
