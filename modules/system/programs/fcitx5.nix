# References:
# https://wiki.nixos.org/wiki/Fcitx5
# https://github.com/hyprwm/Hyprland/discussions/421
# https://discourse.nixos.org/t/pinyin-input-method-in-hyprland-wayland-for-simplified-chinese/49186
{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.fcitx5;
in {
  options.programs.fcitx5 = {
    enable = lib.mkEnableOption "Fcitx5 input method";
  };

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-gtk
          qt6Packages.fcitx5-chinese-addons # Hanzi
          fcitx5-m17n # Pinyin
          fcitx5-material-color
        ];
      };
    };

    # xdg.configFile = {
    #   "fcitx5/conf/classicui.conf" = {
    #     force = true;
    #     text = ''
    #       Theme=Material-Color-Black
    #     '';
    #   };
    # };

    # TODO: Configure
  };
}
