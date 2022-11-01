{pkgs, ...}: {
  home.packages = with pkgs; [
    gnomeExtensions.dash-to-dock
  ];

  dconf.settings = {
    # "org/gnome/shell/extensions/dash-to-dock" = {
    # };
    #     []
    # background-opacity=0.80000000000000004
    # dash-max-icon-size=48
    # dock-position='LEFT'
    # height-fraction=0.90000000000000002
    # preferred-monitor=-2
    # preferred-monitor-by-connector='eDP-1'
  };
}
