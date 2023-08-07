{user, ...}: {
  home-manager.users.${user} = {...}: {
    home.file.".config/hypr/hyprland.conf".text = builtins.readFile ./hyprland.conf;
  };
}
