{pkgs}: {
  service = {
    Unit = {
      Description = "Wayland idle inhibitor";
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=idle:sleep:handle-lid-switch --who=Caffeine --why='Caffeine is enabled' ${pkgs.coreutils}/bin/sleep infinity";
      Restart = "on-failure";
    };
  };
}
