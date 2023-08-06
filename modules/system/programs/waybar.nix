{
  pkgs,
  user,
  hyprland,
  ...
}: {
  environment.systemPackages = with pkgs; [
    waybar
  ];

  home-manager.users.${user} = {
    programs.waybar = {
      enable = true;
      package = hyprland.packages.${pkgs.system}.waybar-hyprland;
    };
  };
}
