# References:
# https://github.com/jakubgs/nixos-config/blob/7e5e89c43274d58699c1ad9630df5b756af3255e/roles/vagrant.nix#L4
{
  config,
  lib,
  user,
  pkgs,
  ...
}: let
  cfg = config.virtualization.vagrant;
in {
  options.virtualization.vagrant = {
    enable = lib.mkEnableOption "Enable Vagrant";
  };

  config = lib.mkIf cfg.enable {
    users.users.${user} = {
      packages = with pkgs; [vagrant];
      extraGroups = ["vboxusers"];
    };
    virtualisation.virtualbox.host.enable = true;

    # Required for vagrant
    boot.kernelParams = pkgs.lib.mkForce ["ipv6.disable=0"];
    networking.enableIPv6 = pkgs.lib.mkForce true;

    # Minimal configuration for NFS support with Vagrant.
    services.nfs.server.enable = true;
    networking.firewall.extraCommands = ''
      ip46tables -I INPUT 1 -i virbr+ -p tcp -m tcp --dport 2049 -j ACCEPT
    '';
  };
}
