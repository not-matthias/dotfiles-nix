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
    home.packages = with unstable; [
      claude-code
    ];

    # Add fish aliases for claude
    programs.fish.shellAbbrs = {
      "cc" = "bunx @anthropic-ai/claude-code";
      "ccc" = "bunx @anthropic-ai/claude-code --continue";
      "ccr" = "bunx @anthropic-ai/claude-code --resume";
    };

    home.file = {
      ".claude/CLAUDE.md" = {
        source = ../shared/AGENTS.md;
      };
      ".claude/commands" = {
        source = ../shared/commands;
        recursive = true;
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
