{pkgs, ...}: {
  programs.dconf.enable = true;
  services.picom.enable = true;

  # Enable sway itself, with few extra packages
  programs.sway = {
    enable = true;
    # remove dmenu and rxvt-unicode from extraPackages
    extraPackages = with pkgs; [xwayland gsettings-desktop-schemas];
  };

  environment.pathsToLink = ["/libexec"]; # links /libexec from derivations to /run/current-system/sw
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
        i3blocks
      ];
      configFile = "/etc/i3.conf";
    };
  };

  environment.etc."i3.conf".text = builtins.readFile ./i3-config;
  # home.file.".config/i3/config".text = builtins.readFile ./i3-config;
}
