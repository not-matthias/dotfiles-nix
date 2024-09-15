{
  lib,
  config,
  ...
}: let
  cfg = config.hardware.zfs;
in {
  options.hardware.zfs = {
    enable = lib.mkEnableOption "ZFS Configuration";
  };

  config = lib.mkIf cfg.enable {
    # Backup
    #
    services.zrepl = {
      enable = true;
      settings = {
        global = {
          logging = [
            {
              type = "syslog";
              level = "debug";
              format = "human";
            }
          ];
        };

        jobs = let
          # Test with: `zrepl test filesystems`
          # https://zrepl.github.io/configuration/filter_syntax.html
          fs = {
            "storage-pool/personal<" = false;
            "storage-pool/personal/phone" = true;
            "storage-pool/personal/photography" = true;

            "storage-pool/technical<" = true;
          };
        in [
          # Snapshot job
          {
            name = "daily-snapshot";
            type = "snap";
            filesystems = fs;
            snapshotting = {
              type = "periodic";
              interval = "15m";
              prefix = "zrepl-";
            };
            pruning = {
              keep = [
                # Keep all manual snapshots
                {
                  type = "regex";
                  regex = "^zrepl-.*$";
                  negate = true;
                }

                # fade-out scheme for snapshots starting with `zrepl-`
                # - keep all created in the last hour
                # - then destroy snapshots such that we keep 24 each 1 hour apart
                # - then destroy snapshots such that we keep 14 each 1 day apart
                # - then destroy all older snapshots
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 14x1d";
                  regex = "^zrepl-.*$";
                }

                # Keep last n snapshots
                # {
                #   type = "last_n";
                #   regex = "^zrepl-.*$";
                #   count = 10;
                # }
              ];
            };
          }

          # Backup job (push to drive)
          #
          # We need this so we can invoke it by cmd:
          # `zrepl signal wakeup push-to-drive`
          #
          {
            name = "push-to-drive";
            type = "push";
            connect = {
              type = "local";
              listener_name = "backup_listener";
              client_identity = "desktop";
            };
            filesystems = fs;
            send.encrypted = false;
            snapshotting.type = "manual";
            replication.protection = {
              initial = "guarantee_resumability";
              # Downgrade protection to guarantee_incremental which uses zfs bookmarks instead of zfs holds.
              # Thus, when we yank out the backup drive during replication
              # - we might not be able to resume the interrupted replication step because the partially received `to` snapshot of a `from`->`to` step may be pruned any time
              # - but in exchange we get back the disk space allocated by `to` when we prune it
              # - and because we still have the bookmarks created by `guarantee_incremental`, we can still do incremental replication of `from`->`to2` in the future
              incremental = "guarantee_incremental";
            };
            pruning = {
              # no-op prune rule on sender (keep all snapshots), job `snapshot` takes care of this
              keep_sender = [
                {
                  type = "regex";
                  regex = ".*";
                }
              ];
              # retain
              keep_receiver = [
                # longer retention on the backup drive, we have more space there
                {
                  type = "grid";
                  grid = "1x1h(keep=all) | 24x1h | 360x1d";
                  regex = "^zrepl-.*";
                }
                # retain all non-zrepl snapshots on the backup drive
                {
                  type = "regex";
                  negate = true;
                  regex = "^zrepl-.*";
                }
              ];
            };
          }

          # Sink for all the jobs from `push_to_drive`
          {
            name = "backup_sink";
            type = "sink";
            root_fs = "backup-pool";
            serve = {
              type = "local";
              listener_name = "backup_listener";
            };
            recv.placeholder.encryption = "inherit";
          }
        ];
      };
    };
  };
}
