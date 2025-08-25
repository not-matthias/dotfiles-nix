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
        # Chinese, Japanese, Korean fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        (google-fonts.override {fonts = ["Poppins"];})
      ];
    };
  };
}
