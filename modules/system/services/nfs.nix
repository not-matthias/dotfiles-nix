# References:
# - https://github.com/edmundmiller/dotfiles/blob/25c5845109299e028ab730d9fada56a9fd9e2982/hosts/unas/nas.nix#L34
{
  config,
  lib,
  ...
}: let
  cfg = config.services.nfs;
in {
  options.services.nfs = {
    enable = lib.mkEnableOption "Enable NFS service";
  };

  config = lib.mkIf cfg.enable {
    services.nfs.server = {
      enable = true;

      # fixed rpc.statd port; for firewall
      lockdPort = 4001;
      mountdPort = 4002;
      statdPort = 4000;

      # TODO: Make this configurable
      # TODO: Dedup
      exports = let
        options = "insecure,rw,sync,no_subtree_check";
        allowIpRanges = [
          # "127.0.0.1/24"
          # "100.121.111.38"
          # "100.64.120.57"

          "192.168.0.1/24" # Local network
          "100.100.100.100/8" # Tailscale
        ];

        fileSystems = [
          "/mnt/data"
          "/mnt/data/personal"
          "/mnt/data/technical"
          "/mnt/data/test"
        ];

        join = lib.concatStringsSep " ";
      in ''
        ${
          join (
            map (fs: ''
              ${fs} ${join (map (r: "${r}(${options})") allowIpRanges)}
            '')
            fileSystems
          )
        }
      '';
    };

    networking.firewall = {
      allowedTCPPorts = [111 2049 4000 4001 4002 20048];
      allowedUDPPorts = [111 2049 4000 4001 4002 20048];
    };
  };
}
