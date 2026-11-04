{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.openbot;
in {
  options.programs.openbot.enable = lib.mkEnableOption "OpenBot with URL scheme handler";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.openbot];

    xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/openbot" = ["openbot.desktop"];
    };
  };
}
