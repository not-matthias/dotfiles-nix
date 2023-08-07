# https://github.com/fufexan/dotfiles/blob/main/home/wayland/swaybg.nix
# https://github.com/linuxmobile/kaku/blob/cdcf0512a6bb44b917cae4be106cae5e48c45f7b/home/wayland/swww.nix#L2
{
  pkgs,
  lib,
  user,
  ...
}: {
  home.file.".wallpaper.png".source = ./wallpaper.png;

  systemd.user.services.swww = {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.swww} init --no-daemon";
      ExecStartPost = "${lib.getExe pkgs.swww} img ~/.wallpaper.png";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
