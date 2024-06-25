{pkgs, ...}: {
  # Currently only works with systemd-resolved
  services.resolved.enable = true;
  networking.resolvconf.enable = false;

  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;
}
