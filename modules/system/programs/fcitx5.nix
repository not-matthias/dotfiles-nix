# References:
# https://wiki.nixos.org/wiki/Fcitx5
# https://github.com/hyprwm/Hyprland/discussions/421
# https://discourse.nixos.org/t/pinyin-input-method-in-hyprland-wayland-for-simplified-chinese/49186
{pkgs, ...}: {
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-chinese-addons # Hanzi
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
}