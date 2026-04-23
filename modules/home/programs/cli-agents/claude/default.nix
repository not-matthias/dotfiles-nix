{
  config,
  lib,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.claude;
in {
  options.programs.cli-agents.claude = {
    enable = mkEnableOption "Claude Code CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      unstable.claude-code
    ];

    # Add fish aliases for claude
    programs.fish.shellAbbrs = {
      "cc" = "claude";
      "ccc" = "claude --continue";
      "ccr" = "claude --resume";
    };

    home.sessionVariables = {
      CLAUDE_CODE_AUTO_COMPACT_WINDOW = "400000";
      CLAUDE_CODE_EFFORT_LEVEL = "medium";
    };

    home.file = {
      ".claude/CLAUDE.md" = {
        source = ../shared/AGENTS.md;
      };
      ".claude/skills" = {
        source = ../shared/skills;
        recursive = true;
      };
      ".claude/agents" = {
        source = ../shared/sub-agents;
        recursive = true;
      };
      ".claude/settings.json" = {
        source = ./settings.json;
      };
    };
  };
}
