{
  config,
  flakes,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.services.self-bot;
in {
  options.services.self-bot = {
    enable = lib.mkEnableOption "Self-bot task controller";
    package = lib.mkOption {
      type = lib.types.package;
      default = flakes.self-bot.packages.${pkgs.stdenv.hostPlatform.system}.default;
      description = "Self-bot package to run.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {config, ...}: {
      home.packages = [cfg.package];
      systemd.user.services.self-bot = {
        Unit.Description = "Self-bot task controller";
        Service = {
          ExecStart = "${lib.getExe cfg.package} serve";
          Environment = "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["default.target"];
      };
    };
  };
}
