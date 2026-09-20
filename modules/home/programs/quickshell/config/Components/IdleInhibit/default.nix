{pkgs}: {
  status = pkgs.writeShellApplication {
    name = "quickshell-idle-inhibit-status";
    runtimeInputs = [pkgs.jq pkgs.systemd];
    text = ''
      if ${pkgs.systemd}/bin/systemctl --user is-active --quiet quickshell-idle-inhibit.service; then
        ${pkgs.jq}/bin/jq -cn '{text: "󰅶", tooltip: "Idle inhibit: ON", class: "active"}'
      else
        ${pkgs.jq}/bin/jq -cn '{text: "󰾪", tooltip: "Idle inhibit: OFF", class: "inactive"}'
      fi
    '';
  };

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
