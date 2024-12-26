{
  # The setup:
  # - Server has a folder: /backup
  # - Laptop and Server can copy and folders into that

  services.restic = {
    # https://francis.begyn.be/blog/nixos-restic-backups
    backups = {
      gdrive = {
        user = "backups";
        repository = "rclone:gdrive:/backups";
        initialize = true; # initializes the repo, don't set if you want manual control
        passwordFile = "<path>";
        timerConfig = {
          onCalendar = "saturday 23:00";
        };
      };

      remote = {
        paths = [
          # "/home/${adminUser.name}/Development"
          # "/home/${adminUser.name}/Documents"
          # "/home/${adminUser.name}/Sync"
          # "/home/${adminUser.name}/Photos"
        ];
        # environmentFile = config.age.secrets.restic-env.path;
        # passwordFile = config.age.secrets.restic-pw.path;
        initialize = true;
        timerConfig.OnCalendar = "*-*-* *:00:00";
        timerConfig.RandomizedDelaySec = "5m";
        extraBackupArgs = [
          "--exclude=\".direnv\""
          "--exclude=\".terraform\""
          "--exclude=\"node_modules/*\""
          "--exclude=\"target/*\""
        ];
      };
    };
  };
}
