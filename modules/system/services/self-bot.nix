{
  config,
  domain,
  flakes,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.services.self-bot;
  origin = "https://self-bot.${domain}";
in {
  options.services.self-bot = {
    enable = lib.mkEnableOption "Self-bot task controller";
    package = lib.mkOption {
      type = lib.types.package;
      default = flakes.self-bot.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "Self-bot package to run.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 4310;
      description = "HTTP listener port for the controller dashboard.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${user}.linger = true;
    networking.hosts."127.0.0.1" = ["self-bot.${domain}"];

    services.caddy.virtualHosts."self-bot.${domain}".extraConfig = ''
      @tailnet remote_ip 127.0.0.1 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48
      handle @tailnet {
        reverse_proxy http://127.0.0.1:${toString cfg.port}
      }
      handle {
        respond "Forbidden" 403
      }
    '';

    home-manager.users.${user} = {config, ...}: {
      home.packages = [cfg.package];
      systemd.user.services.self-bot = {
        Unit.Description = "Self-bot task controller";
        Service = {
          ExecStart = "${lib.getExe cfg.package} --bind 127.0.0.1 --port ${toString cfg.port} --public-origin ${lib.escapeShellArg origin} serve";
          Environment = "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
