{
  pkgs,
  unstable,
  config,
  lib,
  ...
}: let
  cfg = config.services.activitywatch;

  # Tracks physical input instead of the compositor's effective idle state, so
  # an active idle inhibitor cannot report the user as present indefinitely.
  awatcherInputIdle = pkgs.callPackage ../../../pkgs/awatcher {awatcher = unstable.awatcher;};
in {
  config = lib.mkIf cfg.enable {
    home.packages = [
      unstable.aw-qt
    ];

    services.activitywatch = {
      package = unstable.aw-server-rust;
      watchers = {
        awatcher.package = awatcherInputIdle;
        aw-sync.package = unstable.aw-server-rust;
        # Reports the currently playing media via MPRIS (Spotify, browsers, ...)
        aw-watcher-media-player.package = pkgs.aw-watcher-media-player;
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

    systemd.user.services.activitywatch-watcher-niri = {
      Unit = {
        Description = "ActivityWatch Niri watcher";
        After = ["graphical-session.target" "activitywatch.service"];
        PartOf = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.aw-watcher-niri}/bin/aw-watcher-niri";
        Restart = "always";
        RestartSec = 3;
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };
  };
}
