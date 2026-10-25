{
  config,
  domain,
  flakes,
  lib,
  user,
  utils,
  ...
}: let
  home = config.users.users.${user}.home;
  package = flakes.self-bot.packages.${config.nixpkgs.hostPlatform.system}.default;
  port = 4310;
  origin = "https://self-bot.${domain}";
in {
  options.services.self-bot.enable = lib.mkEnableOption "Self Bot Taskwarrior-to-PR controller";

  config = lib.mkIf config.services.self-bot.enable {
    networking.hosts."127.0.0.1" = ["self-bot.${domain}"];

    systemd.services.self-bot = {
      description = "Self Bot Taskwarrior-to-PR controller";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target" "home-manager-${utils.escapeSystemdPath user}.service"];
      # Use the user's configured CLIs, including the OMP credential wrapper.
      path = [config.home-manager.users.${user}.home.path "/run/current-system/sw"];
      environment.HOME = home;
      serviceConfig = {
        User = user;
        WorkingDirectory = home;
        ExecStart = lib.escapeShellArgs [
          (lib.getExe package)
          "--bind"
          "127.0.0.1"
          "--port"
          (toString port)
          "--public-origin"
          origin
          "serve"
        ];
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    services = {
      caddy.virtualHosts."self-bot.${domain}".extraConfig = ''
        @untrusted not remote_ip 127.0.0.1 ::1 100.64.0.0/10 fd7a:115c:a1e0::/48
        respond @untrusted "Forbidden" 403
        reverse_proxy http://127.0.0.1:${toString port}
      '';
      # The existing controller keeps its state and settings at the pre-rename paths.
      restic.paths = [
        "${home}/.local/share/matthias-bot"
        "${home}/.config/matthias-bot"
      ];
    };
  };
}
