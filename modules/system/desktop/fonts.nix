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
        # NixOS:
        carlito
        vegur

        # Chinese, Japanese, Korean fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif

        font-awesome # Icons
        corefonts # MS
        newcomputermodern
        source-code-pro
        jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.roboto-mono
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
