{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr-gpui;
in {
  options.programs.herdr-gpui.enable = lib.mkEnableOption "Herdr GPUI client";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.herdr-gpui];

    xdg.desktopEntries.herdr-gpui = {
      name = "Herdr GPUI";
      comment = "Native client for an existing local Herdr daemon";
      exec = lib.getExe pkgs.herdr-gpui;
      icon = "herdr-gpui";
      terminal = false;
      categories = ["Development"];
    };
  };
}
