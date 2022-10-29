{user, ...}: {
  services = {
    flameshot = {
      enable = true;
      settings = {
        General = {
          savePath = "/home/${user}/";
          saveAsFileExtension = ".png";
          uiColor = "#2d0096";
          showHelp = "false";
          disabledTrayIcon = "false";
        };
      };
    };
  };
}
