{...}: {
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=100M
    MaxRetentionSec=7day

    # Store journals persistently but compress them
    Storage=persistent
    Compress=yes
  '';

  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  # Systemd memory limits to prevent excessive memory usage
  systemd.extraConfig = ''
    DefaultMemoryAccounting=yes
    DefaultMemoryMax=1G
    DefaultTasksMax=4096
    LogLevel=notice
  '';
}
