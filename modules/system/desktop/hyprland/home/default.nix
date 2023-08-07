{user, ...}: {
  home-manager.users.${user} = {...}: {
    imports = [
      ./swayidle.nix
      ./swayidle.nix
      ./swww.nix
    ];

    home.file.".config/hypr/hyprland.conf".text = builtins.readFile ./hyprland.conf;
  };
}
