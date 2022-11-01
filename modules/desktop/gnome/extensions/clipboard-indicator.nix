{pkgs, ...}: {
  home.packages = with pkgs; [
    gnomeExtensions.clipboard-indicator
  ];

  dconf.settings = {
    history = 100;
    toggle-menu = [
      "<Super>v"
    ];
  };
}
