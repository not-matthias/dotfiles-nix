{ pkgs, specialArgs, ... }:
{

  home.file.".config/alacritty/alacritty.yml".source = ./alacritty.yml;
  programs.alacritty = {
    enable = true;
    settings = {
      live_config_reload = true;
      bell = {
        animation = "EaseOutExpo";
        duration = 5;
        color = "#ffffff";
      };
      colors = {
        primary = {
          background = "#040404";
          foreground = "#c5c8c6";
        };
      };
      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        size = 10.0;
      };
      selection.save_to_clipboard = true;
      shell.program = "${pkgs.fish}/bin/fish";
      window = {
        decorations = "full";
        opacity = 0.85;
        dimensions = {
          columns = 100;
					lines = 40; # Try 25
				};
        padding = {
          x = 5;
          y = 5;
        };
      };
    };
  };
}