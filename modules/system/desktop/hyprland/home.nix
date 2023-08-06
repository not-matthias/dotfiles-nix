{user, ...}: {
  home-manager.users.${user} = {
    home.file.".config/hypr/hyprland.conf" = builtins.readFile ./hyprland.conf;
  };
}
