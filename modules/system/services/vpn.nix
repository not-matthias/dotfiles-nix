{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.services.vpn;
in {
  options.services.vpn = {
    enable = lib.mkEnableOption "VPN Configuration";
  };

  config = lib.mkIf cfg.enable {
    # Currently only works with systemd-resolved
    services.resolved.enable = true;
    networking.resolvconf.enable = false;

    services.mullvad-vpn.enable = true;
    services.mullvad-vpn.package = pkgs.mullvad-vpn;
  };
}
