{
  user,
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      pkgs,
      unstable,
      ...
    }: {
      imports = [
        ./swayidle.nix
        ./swayidle.nix
        ./swww.nix
        ./wlsunset.nix
      ];

      home.packages = with pkgs; [
        alsa-utils # for volume control
        brightnessctl # for brightness control
        playerctl # for media control
        networkmanagerapplet # for network control

        wtype

        # screenshot tools
        grim
        slurp
        swappy
        tesseract

        # hypr utils
        unstable.hyprsunset
      ];

      home.file.".config/hypr/env.conf".text = builtins.readFile ./conf/env.conf;
      home.file.".config/hypr/hyprland.conf".text =
        builtins.readFile ./conf/hyprland.conf
        + "\n"
        + builtins.readFile ./conf/fcitx5.conf;
      home.file.".config/hypr/keybinds.conf".text = builtins.readFile ./conf/keybinds.conf;
      home.file.".config/hypr/startup.conf".text = builtins.readFile ./conf/startup.conf;
      home.file.".config/hypr/windowrule.conf".text = builtins.readFile ./conf/windowrule.conf;
    };
  };
}
