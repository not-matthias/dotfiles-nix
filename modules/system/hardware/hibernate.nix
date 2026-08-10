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
    # Disable zram for hibernation: its ~27 GiB of volatile anon pages are
    # snapshotted into the image anyway; 34 GiB disk swap remains.
    zramSwap.enable = lib.mkForce false;

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
