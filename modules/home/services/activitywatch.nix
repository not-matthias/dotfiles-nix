{
  unstable,
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
        After = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
