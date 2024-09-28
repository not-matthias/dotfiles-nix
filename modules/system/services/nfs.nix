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
        commonOptions = "insecure,ro,sync,no_subtree_check";
        clients = [
          "127.0.0.1/24"
          "192.168.0.1/24"
          "100.121.111.38"
          "100.64.120.57"
        ];
        mountPoints = [
          "/mnt/data"
          "/mnt/data/test"
        ];
      in ''
        ${builtins.concatStringsSep "\n" (builtins.map (
            mountPoint: "${mountPoint} ${builtins.concatStringsSep " " (builtins.map (client: "${client}(${commonOptions})") clients)}"
          )
          mountPoints)}
      '';
    };

    networking.firewall = {
      allowedTCPPorts = [111 2049 4000 4001 4002 20048];
      allowedUDPPorts = [111 2049 4000 4001 4002 20048];
    };
  };
}
