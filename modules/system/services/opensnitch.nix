{
  config,
  lib,
  user,
  ...
}: {
  config = lib.mkIf config.services.opensnitch.enable {
    home-manager.users.${user} = {
      services.opensnitch-ui.enable = true;
    };

    services.opensnitch = {
      settings = {
        DefaultAction = "deny";
        ProcMonitorMethod = "proc"; # ebpf has issues with kernel >= 6.19
        LogLevel = 2;
      };
    };
  };
}
