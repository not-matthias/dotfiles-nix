{
  config,
  flakes,
  ...
}: {
  imports = [flakes.timeguard.nixosModules.default];

  age.secrets.timeguard-rules = {
    file = ../../../secrets/timeguard-rules.age;
    owner = "root";
    group = "timeguard-proxy";
    mode = "0440";
  };

  services.timeguard.rulesFile = config.age.secrets.timeguard-rules.path;
}
