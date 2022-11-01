{pkgs, ...}: {
  home.packages = with pkgs; [
    gnomeExtensions.clipboard-indicator
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/clipboard-indicator" = {
      history-size = 100;
      toggle-menu = [
        "<Super>v"
      ];
    };
  };
}
