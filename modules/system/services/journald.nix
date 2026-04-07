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

  # NOTE: Avoid setting DefaultMemoryMax here — it applies to all systemd
  # services/scopes and kills Electron apps (Chrome, Slack) during memory pressure.
  systemd.settings = {
    Manager = {
      DefaultMemoryAccounting = "yes";
      DefaultTasksMax = "4096";
      LogLevel = "notice";
    };
  };
}
