{
  pkgs,
  lib,
  ...
}: {
  home.file.".bg.png".source = ./wallpaper.png;
  systemd.user.services.swww = {
    Unit = {
      Description = "Wayland wallpaper daemon";
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.swww} init --no-daemon";
      ExecStartPost = "${lib.getExe pkgs.swww} img ~/.bg.png";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
