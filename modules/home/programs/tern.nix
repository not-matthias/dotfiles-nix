{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.tern;
in {
  options.programs.tern.enable = lib.mkEnableOption "Tern terminal with persistent sessions";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.tern];

    xdg.desktopEntries.tern = {
      name = "Tern";
      comment = "Native terminal with persistent sessions";
      exec = lib.getExe pkgs.tern;
      terminal = false;
      categories = ["System" "TerminalEmulator"];
    };
  };
}
