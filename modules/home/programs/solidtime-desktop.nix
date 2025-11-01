{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.solidtime-desktop;
in {
  options.programs.solidtime-desktop = {
    enable = lib.mkEnableOption "Solidtime Desktop with URL scheme handler";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.solidtime-desktop];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/solidtime" = ["solidtime.desktop"];
      };
    };
  };
}
