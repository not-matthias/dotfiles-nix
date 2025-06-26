# Based on this: bobvanderlinden/aw-watcher-window-hyprland
{
  unstable,
  flakes,
  config,
  lib,
  ...
}: let
  cfg = config.services.activitywatch;
in {
  config = lib.mkIf cfg.enable {
    services.activitywatch = {
      package = unstable.aw-server-rust;
    };

    systemd.user.services.activitywatch-watcher-window-hyprland = {
      Unit = {
        Description = "ActivityWatch watcher 'aw-watcher-window-hyprland'";
        After = [
          "graphical-session.target"
          "activitywatch.service"
        ];
        BindsTo = ["activitywatch.target"];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      Service = {
        ExecStart = lib.getExe flakes.aw-hyprland.packages.${unstable.system}.aw-watcher-window-hyprland;
      };
      Install = {
        WantedBy = ["activitywatch.target"];
      };
    };
  };
}
