{pkgs, ...}: let
  suspendScript = pkgs.writeShellScript "suspend-script" ''
    #!${pkgs.runtimeShell}
    # Don't suspend if music is playing
    if ${pkgs.playerctl}/bin/playerctl status 2>/dev/null | grep -q "Playing"; then
        exit 0
    fi
    ${pkgs.systemd}/bin/systemctl suspend
  '';
in {
  services.swayidle = {
    enable = true;
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        event = "lock";
        command = "${pkgs.swaylock-effects}/bin/swaylock -fF";
      }
    ];
    timeouts = [
      {
        timeout = 60 * 5;
        command = suspendScript.outPath;
      }
    ];
  };
}
