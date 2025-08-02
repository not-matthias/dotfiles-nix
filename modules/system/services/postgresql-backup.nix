{
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "/var/backup/postgresql";
  };

  services.restic.paths = [
    "/var/backup/postgresql"
  ];
}
