{pkgs, ...}: let
  exclude = [
    ".cache"
    "cache"
    ".tmp"
    ".temp"
    "tmp"
    "temp"
    ".log"
    "log"
    ".Trash"
    ".git"
    "node_modules"
    "target"
    "build"
    "result"
    ".devenv"
    "*.iso"
    "*.img"
    "*.deb"
    "Cache"
    "CachedData"
    "cache"
    ".mozilla/firefox"
  ];

  pruneOpts = [
    # "--keep-within-hourly 18h"
    # "--keep-within-daily 7d"
    # "--keep-within-weekly 35d"
    # "--keep-within-monthly 12m"
    # "--keep-within-yearly 75y"
    # "--max-unused 10G"

    "--keep-daily 5"
    "--keep-weekly 1"
    "--keep-monthly 1"
  ];
  extraBackupArgs = [
    "--exclude-if-present=.nobak"
    "--exclude-caches"
  ];
in {
  environment.systemPackages = with pkgs; [
    restic
  ];

  services.restic = {
    # Enable the Restic REST server.
    # See: https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#rest-server
    #
    server = {
      # enable = ?;
      privateRepos = true;
      dataDir = "/mnt/data/restic";
      listenAddress = "11417";
      extraFlags = [
        "--no-auth"
      ];
      appendOnly = true;
    };

    backups = {
      nas = {
        initialize = true;
        repository = "rest:http://desktop.local:11417/";
        passwordFile = "/var/lib/restic/remote-rest-password"; # See Bitwarden
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
          RandomizedDelaySec = "20m";
        };
        exclude = exclude;
        pruneOpts = pruneOpts;
        extraBackupArgs = extraBackupArgs;
      };

      # Backup to a local folder:
      # local = {
      #   initialize = true;
      #   repository = "/var/lib/restic/local-backup";
      #   passwordFile = "/var/lib/restic/password";
      #   timerConfig = {
      #     OnCalendar = "hourly";
      #     # OnCalendar = "*-*-* 0..23/1:00:00";
      #     Persistent = true;
      #     RandomizedDelaySec = "20m";
      #   };
      #   exclude = excludePatterns;
      #   pruneOpts = pruneOpts;
      #   extraBackupArgs = extraBackupArgs;
      # };
    };
  };
}
