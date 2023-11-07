{
  services.wlsunset = {
    enable = true;
    latitude = "48.210033";
    longitude = "16.363449";
    temperature = {
      day = 6500;
      night = 2700;
    };
  };
  systemd.user.services.wlsunset = {
    Install.WantedBy = ["default.target"];
    Service.Restart = "always";
  };
}
