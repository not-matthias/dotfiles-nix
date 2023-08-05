{
  # https://discourse.nixos.org/t/fprintd-on-t440p/1350/3
  services.fprintd = {
    enable = true;
    # tod = {
    #   enable = true;
    #   driver = pkgs.libfprint-2-tod1-goodix;
    # };
  };

  # https://old.reddit.com/r/NixOS/comments/z7i83r/fingertip_tip_start_fprintd_at_boot_for_a_quick/
  systemd.services.fprintd = {
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "simple";
  };

  security.pam.services.login.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;
}
