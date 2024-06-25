# References:
# - https://github.com/johnae/world/blob/5a4d2a58d9b4d5e6996febdf8808b4829067322e/profiles/restic-backup.nix#L13
{...}: let
  # paths = [
  #   "/etc/nixos"
  #   "/var/lib"
  #   "/home"
  # ];
  # # https://github.com/rubo77/rsync-homedir-excludes
  # ignorePatterns = [
  #   "/var/lib/systemd"
  #   "/var/lib/containers"
  #   "/var/lib/nixos-containers"
  #   "/var/lib/lxcfs"
  #   "/var/lib/docker"
  #   "/var/lib/flatpak"
  #   "/home/*/ignore"
  #   "/home/*/.cache"
  #   "/home/*/.local/share/containers"
  #   "/home/*/.local/share/Trash"
  #   "/var/lib/jellyfin/transcodes"
  #   # general
  #   ".cache"
  #   "cache"
  #   ".tmp"
  #   ".temp"
  #   "tmp"
  #   "temp"
  #   ".log"
  #   "log"
  #   ".Trash"
  # ];
in {
  services.restic = {
    # backups = {
    #   remote = {
    #     paths = [
    #   "/home/not-matthias/Development"
    #   "/home/not-matthias/Documents"
    #   "/home/not-matthias/Sync"
    #   "/home/not-matthias/Photos"
    # ];

    # TODO:
    # environmentFile = "/run/agenix/restic-env";
    # passwordFile = "/run/agenix/restic-pw";
    # repository = "s3:https://b0850d27a4d43d7d0f8d36ebc6a1bfab.r2.cloudflarestorage.com/restic-9000-b147";
    # initialize = true;

    # timerConfig.OnCalendar = "0/6:00:00";
    # extraPruneOpts = [ "--keep-last 4" ];

    #     timerConfig = {
    #       onCalendar = "hourly";
    #       OnCalendar = "*-*-* *:00:00";
    #       RandomizedDelaySec = "5m";
    #     };
    #     extraBackupArgs = [
    #       "--exclude=\".direnv\""
    #       "--exclude=\"node_modules/*\""
    #       "--exclude=\"target/*\""
    #     ];
    #   };
    # };
  };

  # TODO: prunebackups?
  #   https://github.com/ghuntley/ghuntley-monorepo-retired/blob/5325e617c44afe4ca10787d79a74ecad4dda48a2/infra/homelab/ghuntley-com.nix#L119C20-L119C32
}
