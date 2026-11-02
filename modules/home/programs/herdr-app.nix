{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr-app;
in {
  options.programs.herdr-app.enable = lib.mkEnableOption "Herdr desktop app and core, with updates managed by Nix";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.herdr-app pkgs.herdr-core];

    xdg.desktopEntries.herdr-app = {
      name = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = lib.getExe pkgs.herdr-app;
      icon = "herdr-app";
      terminal = false;
      categories = ["Development"];
      settings.StartupWMClass = "herdr-app";
    };
  };
}
