{
  config,
  lib,
  unstable,
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
      # bun add -g @sourcegraph/amp@latest
      unstable.amp-cli
    ];

    home.file = {
      # Shared instruction files
      ".amp/INSTRUCTIONS.md" = {
        source = ../shared/INSTRUCTIONS.md;
      };
      ".amp/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".amp/commands" = {
        source = ../shared/commands;
        recursive = true;
      };
      ".amp/skills" = {
        source = ../shared/skills;
        recursive = true;
      };
    };
  };
}
