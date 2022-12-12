{pkgs, ...}: {
  home.packages = with pkgs; [
    gnomeExtensions.gnome-bedtime
  ];

  dconf.settings = {
    "org/gnome/shell/extensions/bedtime-mode" = {
      automatic-schedule = true;
      schedule-start-hours = 7;
      ondemand-button-location = "menu";
      ondemand-button-bar-onoff-indicator = true;
      bedtime-mode-active = true;
    };
  };
}
