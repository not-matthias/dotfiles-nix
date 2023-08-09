{user, ...}: {
  home-manager.users.${user} = {pkgs, ...}: {
    imports = [
      ./swayidle.nix
      ./swayidle.nix
      ./swww.nix
    ];

    home.packages = with pkgs; [
      pamixer # for volume control
      brightnessctl # for brightness control
      playerctl # for media control

      wofi-emoji

      # screenshot tools
      grim
      slurp
      swappy
      tesseract
    ];

    home.file.".config/hypr/env.conf".text = builtins.readFile ./conf/env.conf;
    home.file.".config/hypr/hyprland.conf".text = builtins.readFile ./conf/hyprland.conf;
    home.file.".config/hypr/keybinds.conf".text = builtins.readFile ./conf/keybinds.conf;
    home.file.".config/hypr/startup.conf".text = builtins.readFile ./conf/startup.conf;
    home.file.".config/hypr/windowrule.conf".text = builtins.readFile ./conf/windowrule.conf;
  };
}
