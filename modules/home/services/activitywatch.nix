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
    home.packages = [
      unstable.aw-qt
    ];

    services.activitywatch = {
      package = unstable.aw-server-rust;
      watchers = {
        awatcher.package = unstable.awatcher;
        aw-sync.package = unstable.aw-server-rust;
      };
    };

    # awatcher should start and stop depending on wayland-session.target
    # starting activitywatch should only start awatcher if wayland-session.target is active
    systemd.user.services.activitywatch-watcher-awatcher = {
      Unit = {
        After = ["wayland-session.target"];
        Requisite = ["wayland-session.target"];
        PartOf = ["wayland-session.target"];
      };
      Install = {WantedBy = ["wayland-session.target"];};
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
