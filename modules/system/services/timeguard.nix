{flakes, ...}: {
  imports = [flakes.timeguard.nixosModules.default];

  services.timeguard.settings.rule = [
    {
      name = "focus-distractions";
      domains = ["reddit.com" "x.com" "youtube.com" "twitch.tv"];
      schedule = {
        days = ["mon" "tue" "wed" "thu" "fri"];
        start = "09:00";
        end = "19:00";
      };
    }
  ];
}
