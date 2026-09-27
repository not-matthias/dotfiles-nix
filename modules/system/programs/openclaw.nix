{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.programs.openclaw;
in {
  options.programs.openclaw.enable = lib.mkEnableOption "OpenClaw desktop app and Docker gateway";

  config = lib.mkIf cfg.enable {
    home-manager.users.${user}.home.packages = [pkgs.openclaw-desktop];

    virtualisation.oci-containers.containers.openclaw-gateway = {
      image = "ghcr.io/openclaw/openclaw@sha256:0a5ff5e682e62afa19149df126aa50063bf65ef885b5c94713ce32dc0eb12e15";
      volumes = ["/home/${user}/.openclaw:/home/${user}/.openclaw"];
      environment = {
        HOME = "/home/${user}";
        XDG_CACHE_HOME = "/tmp/openclaw-cache";
      };
      extraOptions = ["--network=host"];
      cmd = ["node" "openclaw.mjs" "gateway" "--bind" "loopback" "--allow-unconfigured"];
    };
  };
}
