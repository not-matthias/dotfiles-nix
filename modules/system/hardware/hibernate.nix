{
  config,
  lib,
  ...
}: let
  cfg = config.hardware.hibernate;
in {
  options.hardware.hibernate.enable = lib.mkEnableOption "Hibernation tuning";

  config = lib.mkIf cfg.enable {
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
