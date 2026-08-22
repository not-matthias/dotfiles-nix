{
  config,
  lib,
  ...
}: let
  cfg = config.hardware.hibernate;
in {
  options.hardware.hibernate = {
    enable = lib.mkEnableOption "Hibernation tuning";
  };

  config = lib.mkIf cfg.enable {
    # zram absorbs transient memory-pressure spikes (compressed, RAM-resident)
    # before overflowing to the slower LUKS disk swap partition, which keeps
    # backing hibernation unchanged via boot.resumeDevice. Pages already in
    # zram at hibernation time are still RAM-resident and get captured in the
    # image as ordinary memory, so this doesn't duplicate or break the snapshot.
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
      priority = 100;
    };

    # s2idle drains the battery on this Framework, so fall through to
    # hibernation after 30 minutes of suspend.
    systemd.sleep.settings.Sleep = lib.mkForce {
      AllowSuspend = "yes";
      AllowHibernation = "yes";
      AllowSuspendThenHibernate = "yes";
      AllowHybridSleep = "yes";
      HibernateDelaySec = "30min";
    };

    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
      HandlePowerKey = "suspend-then-hibernate";
    };
  };
}
