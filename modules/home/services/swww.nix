# https://github.com/fufexan/dotfiles/blob/main/home/wayland/swaybg.nix
# https://github.com/linuxmobile/kaku/blob/cdcf0512a6bb44b917cae4be106cae5e48c45f7b/home/wayland/swww.nix#L2
{
  lib,
  config,
  ...
}: let
  cfg = config.services.swww;
in {
  options.services.swww = {
    enable = lib.mkEnableOption "swww wayland wallpaper daemon";

    wallpaper = lib.mkOption {
      type = lib.types.path;
      description = "Path to wallpaper image";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".wallpaper.png".source = cfg.wallpaper;
    # services.swww.enable =
  };
}
