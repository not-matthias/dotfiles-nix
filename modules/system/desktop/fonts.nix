{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.desktop.fonts;
in {
  options.desktop.fonts.enable = lib.mkEnableOption "Fonts";

  config = lib.mkIf cfg.enable {
    # Expose fonts to applications that scan directories instead of using fontconfig.
    fonts.fontDir.enable = true;

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      # Chinese, Japanese, Korean fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      (google-fonts.override {fonts = ["Poppins"];})
    ];
  };
}
