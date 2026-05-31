{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.amp;
in {
  options.programs.cli-agents.amp = {
    enable = mkEnableOption "AMP CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.amp-cli
    ];

    home.file = {
      # Shared instruction files
      ".amp/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".amp/skills" = {
        source = ../shared/skills;
        recursive = true;
      };
    };
  };
}
