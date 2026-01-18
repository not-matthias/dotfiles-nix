{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.opencode;
in {
  options.programs.cli-agents.opencode = {
    enable = mkEnableOption "OpenCode CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
    ];

    home.file = {
      # Shared instruction files
      ".opencode/INSTRUCTIONS.md" = {
        source = ../shared/INSTRUCTIONS.md;
      };
      ".opencode/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".opencode/commands" = {
        source = ../shared/commands;
        recursive = true;
      };
      ".opencode/skills" = {
        source = ../shared/skills;
        recursive = true;
      };
    };
  };
}
