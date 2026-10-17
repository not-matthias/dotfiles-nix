{
  config,
  domain,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.programs.openclaw;
  gatewayPort = 18789;
in {
  options.programs.openclaw.enable = lib.mkEnableOption "OpenClaw desktop app and Docker gateway";

  config = lib.mkIf cfg.enable {
    home-manager.users.${user}.home.packages = [pkgs.openclaw-desktop];

    # Docker creates missing bind-mount sources as root; the image runs as uid 1000.
    systemd.tmpfiles.rules = ["d /home/${user}/.openclaw 0700 ${user} users -"];

    virtualisation.oci-containers.containers.openclaw-gateway = {
      # OpenClaw 2026.10.4 (2026-10-17); keep in sync with pkgs/openclaw.nix.
      image = "ghcr.io/openclaw/openclaw@sha256:614004ec2cf2e6095124ea544dc8d950c49306aef445a1fc300b88717e24261a";
      volumes = ["/home/${user}/.openclaw:/home/${user}/.openclaw"];
      environment = {
        HOME = "/home/${user}";
        XDG_CACHE_HOME = "/tmp/openclaw-cache";
      };
      extraOptions = ["--network=host"];
      cmd = ["node" "openclaw.mjs" "gateway" "--bind" "loopback" "--port" (toString gatewayPort) "--allow-unconfigured"];
    };

    # Reach this via DuckDNS (Tailscale IP), not a 127.0.0.1 hosts entry: the gateway
    # rejects proxied requests whose forwarded client address is loopback.
    services.caddy.virtualHosts."openclaw.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString gatewayPort}
    '';
  };
}
