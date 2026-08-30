{flakes, ...}: {
  imports = [flakes.timeguard.nixosModules.default];

  services.timeguard.settings.rule = [
    {
      name = "distraction-window";
      domains = ["reddit.com" "x.com" "youtube.com" "twitch.tv"];
      schedule = {
        days = ["sun" "mon" "tue" "wed" "thu" "fri" "sat"];
        start = "19:00";
        end = "18:30";
      };
    }
  ];
}
