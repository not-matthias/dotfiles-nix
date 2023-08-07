{user, ...}: {
  home-manager.users.${user} = {...}: {
    imports = [
      ./swayidle.nix
      ./swayidle.nix
      ./swww.nix
    ];

    home.file.".config/hypr/hyprland.conf".text = builtins.readFile ./conf/hyprland.conf;
    home.file.".config/hypr/keybinds.conf".text = builtins.readFile ./conf/keybinds.conf;
    home.file.".config/hypr/startup.conf".text = builtins.readFile ./conf/startup.conf;
    home.file.".config/hypr/windowrule.conf".text = builtins.readFile ./conf/windowrule.conf;
  };
}
