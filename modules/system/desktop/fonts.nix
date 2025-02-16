{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.desktop.fonts;
in {
  options.desktop.fonts = {
    enable = lib.mkEnableOption "Fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        newcomputermodern
        carlito # NixOS
        vegur # NixOS
        source-code-pro
        jetbrains-mono
        font-awesome # Icons
        corefonts # MS
        (nerdfonts.override {
          # Nerdfont Icons override
          fonts = [
            "FiraCode"
            "RobotoMono"
          ];
        })
        (google-fonts.override {fonts = ["Poppins"];})
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting.enable = false;
        subpixel.lcdfilter = "default";
      };
    };
  };
}
