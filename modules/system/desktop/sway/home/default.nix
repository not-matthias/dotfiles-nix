{user, ...}: {
  home-manager.users.${user} = {
    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true; # Fixes common issues with GTK 3 apps
      config = let
        modifier = "Mod4";
      in {
        modifier = modifier;
        floating.modifier = modifier;
        terminal = "alacritty";
        startup = [
          {command = "zen-beta";}
        ];
        keybindings = {
          "${modifier}+d" = "exec walker";
          "${modifier}+r" = "exec walker";
        };
        input = {
          "type:keyboard" = {
            "repeat_delay" = "300";
            "repeat_rate" = "30";
            "xkb_options" = "ctrl:nocaps";
            "xkb_numlock" = "enabled";
          };
          "type:touchpad" = {
            natural_scroll = "disabled";
            tap = "enabled";
            middle_emulation = "disabled";
          };
        };
      };
      extraConfig = builtins.readFile ./sway.conf;
    };
  };
}
