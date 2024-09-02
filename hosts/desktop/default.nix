{...}: {
  imports = [(import ./hardware-configuration.nix)];

  # TODO: Move to self-hosted folder
  services.paperless = {
    enable = true;
    port = 11432;
  };

  services.outline = {
    enable = false;
    port = 11431;
  };

  services.gitea = {
    enable = true;
    settings.server.HTTP_PORT = 11430;
  };

  services.adguardhome = {
    enable = false;
    host = "0.0.0.0";
    port = 11429;
    # TODO: openFirewall?
  };

  services.jellyfin = {
    enable = true;
    # openFirewall
    #port = 11429;
  };
  services.jellyseerr = {
    enable = true;
    port = 5055;
  };

  services.home-assistant = {
    enable = true;
    config.http.server_port = 8123;
  };

  # Keep track of SMART data
  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web.listen.port = 11428;
    settings.notify.urls = [
      "ntfy://ntfy.sh/desktop-zfs"
    ];
  };

  # Don't need this because of scrutiny
  # services.smartd = {
  #   enable = true;
  #   autodetect = true;
  #   extraOptions = ["--interval=7200"];
  #   notifications.test = true;
  #   notifications.wall.enable = true;
  #   notifications.x11.enable = true;
  # };

  # TODO: Works with free version as well
  # services.ntfy-sh = {
  #   enable = true;
  #   # https://docs.ntfy.sh/config/#config-options
  #   settings = {
  #     listen-http = "127.0.0.1:2586";
  #     base-url = "http://localhost";
  #   };
  # };

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
        #monitoring = [
        #  {
        #    type = "prometheus";
        #    listen = ":9811";
        #    listen_freebind = true;
        #  }
        #];
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

  ## monitoring
  services.grafana = {
    enable = true;
    settings.server = {
      enable_gzip = true;
      http_port = 1230;
    };
  };

  services.prometheus = {
    enable = true;
    scrapeConfigs = [
    ];
    rules = [
    ];
  };

  networking = {
    hostName = "desktop";
    networkmanager.enable = true;
  };

  desktop.hyprland = {
    enable = true;
    useNvidia = true;
  };

  hardware.nvidia.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
    #permitRootLogin = "yes";
  };

  # virtualisation = {
  #   single-gpu-passthrough.enable = true;
  #   vfio = {
  #     enable = true;
  #     IOMMUType = "amd";
  #     # devices = ["10de:1f08" "10de:10f9"];
  #     # ignoreMSRs = true;
  #     # disableEFIfb = true;
  #     loadVfioPci = true;
  #     # blacklistNvidia = true;
  #     # enableNestedVirt = true;
  #   };
  # };

  # Lots of these are from the default `configuration.nix`
  boot = {
    # Bootloader.
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };

    # Enable swap on luks
    initrd = {
      luks.devices."luks-0d6a9387-fa29-4abb-b966-f619b3ababfc".device = "/dev/disk/by-uuid/0d6a9387-fa29-4abb-b966-f619b3ababfc";
    };
  };
}
