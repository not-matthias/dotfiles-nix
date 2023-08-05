# References:
# - https://github.com/QuentinI/dotnix/blob/dfc55407f3d99c3a46f80ba74052975ea693d548/modules/services/activitywatch.nix#L5
# - https://github.com/meain/dotfiles/blob/master/home-manager/.config/home-manager/home.nix#L343-L366
# - https://stackoverflow.com/a/58244114
# - https://unix.stackexchange.com/questions/564443/what-does-restart-on-abort-mean-in-a-systemd-service
# - https://discourse.nixos.org/t/nixos-22-11-systemd-user-services-dont-start-automatically-but-global-ones-do/24809
{pkgs, ...}: {
  home.packages = with pkgs; [
    aw-server-rust
    aw-watcher-afk
    aw-watcher-window
  ];

  systemd.user.services = {
    activitywatch = {
      Unit.Description = "ActivityWatch Server (Rust implementation)";
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.aw-server-rust}/bin/aw-server";
        Restart = "on-abort";
      };

      Install = {WantedBy = ["default.target"];};
    };

    activitywatch-afk = {
      Unit.Description = "ActivityWatch Watcher AFK";
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-afk";
        Restart = "on-abort";
      };
      Install.WantedBy = ["default.target"];
    };

    activitywatch-window = {
      Unit.Description = "ActivityWatch Watcher Window";
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-window";
        Restart = "on-abort";
        RestartSec = 5;
      };
      Install.WantedBy = ["default.target"];
    };
  };
}
