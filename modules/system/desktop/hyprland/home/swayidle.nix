{pkgs, ...}: let
  # suspendScript = pkgs.writeShellScript "suspend-script" ''
  #   ${pkgs.pipewire}/bin/pw-cli i all | ${pkgs.ripgrep}/bin/rg running
  #   # only suspend if audio isn't running
  #   if [ $? == 1 ]; then
  #     ${pkgs.systemd}/bin/systemctl suspend
  #   fi
  # '';
  suspendScript = pkgs.writeShellScript "suspend-script" ''
    ${pkgs.systemd}/bin/systemctl suspend
  '';
in {
  # screen idle
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
        timeout = 180;
        command = suspendScript.outPath;
      }
    ];
  };
}
