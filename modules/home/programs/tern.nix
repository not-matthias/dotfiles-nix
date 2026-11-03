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

    home.activation.ternMultiplexer = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.tern} plugin link ${../../../pkgs/tern-plugins/multiplexer}
    '';

    home.activation.ternSpaces = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.tern} plugin link ${../../../pkgs/tern-plugins/spaces}
    '';

    xdg.desktopEntries.tern = {
      name = "Tern";
      comment = "Native terminal with persistent sessions";
      exec = lib.getExe pkgs.tern;
      terminal = false;
      categories = ["System" "TerminalEmulator"];
    };
  };
}
