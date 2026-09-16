{pkgs}: {
  status = pkgs.writeShellApplication {
    name = "eww-idle-inhibit-status";
    runtimeInputs = [pkgs.jq pkgs.systemd];
    text = ''
      if ${pkgs.systemd}/bin/systemctl --user is-active --quiet eww-idle-inhibit.service; then
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
      ExecStart = "${pkgs.wlinhibit}/bin/wlinhibit";
      Restart = "on-failure";
    };
  };
}
