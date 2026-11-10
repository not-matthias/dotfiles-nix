{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.tern;
  spacesRoot = ../../../pkgs/tern-plugins/spaces;
  # Tests and benchmarks stay out of the linked plugin, and editing them does not relink it.
  spaces = lib.fileset.toSource {
    root = spacesRoot;
    fileset = lib.fileset.unions [(spacesRoot + "/plugin.toml") (spacesRoot + "/src")];
  };
in {
  options.programs.tern.enable = lib.mkEnableOption "Tern terminal with persistent sessions";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.tern];

    home.activation.ternMultiplexer = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.tern} plugin link ${../../../pkgs/tern-plugins/multiplexer}
    '';

    home.activation.ternSpaces = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${lib.getExe pkgs.tern} plugin link ${spaces}
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
