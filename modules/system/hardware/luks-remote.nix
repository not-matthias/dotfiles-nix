# Remote disk unlocking: https://nixos.wiki/wiki/Remote_disk_unlocking#Usage
{
  config,
  lib,
  ...
}: let
  cfg = config.boot.luks-remote;
in {
  options.boot.luks-remote = {
    enable = lib.mkEnableOption "Enable LUKS remote disk unlocking";
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.string;
      default = [];
      description = ''
        List of authorized SSH public keys that are allowed to unlock the remote disk.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable boot networking and set default DNS server, as
    # the self-hosted one will not be started at boot.
    #
    boot.kernelParams = ["ip=dhcp"];
    networking.nameservers = ["1.1.1.1" "1.0.0.1"];

    boot.initrd = {
      availableKernelModules = ["r8169"]; # Find with: lspci -v | grep -iA8 'network\|ethernet'
      systemd.users.root.shell = "/bin/cryptsetup-askpass";
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          authorizedKeys = cfg.authorizedKeys;
          hostKeys = [
            "/etc/ssh/ssh_host_rsa_key"
          ];
        };
      };
    };
  };
}
