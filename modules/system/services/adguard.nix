{
  lib,
  config,
  ...
}: let
  cfg = config.services.adguard;
in {
  options.services.adguard = {
    enableDns = lib.mkEnableOption "Enable AdguardDns";
  };

  config = lib.mkIf cfg.enableDns {
    services.resolved.enable = true;
    networking.nameservers = lib.mkForce ["100.64.120.57"];
  };
}
