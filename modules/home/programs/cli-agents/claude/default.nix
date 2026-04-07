{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.claude;
  superpowers = import ../shared/superpowers.nix {inherit (pkgs) fetchFromGitHub;};
in {
  options.programs.cli-agents.claude = {
    enable = mkEnableOption "Claude Code CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.claude-code
    ];

    # Add fish aliases for claude
    programs.fish.shellAbbrs = {
      "cc" = "bunx @anthropic-ai/claude-code";
      "ccc" = "bunx @anthropic-ai/claude-code --continue";
      "ccr" = "bunx @anthropic-ai/claude-code --resume";
    };

    home.sessionVariables = {
      CLAUDE_CODE_AUTO_COMPACT_WINDOW = "400000";
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

      # Superpowers skills and commands
      ".claude/skills/superpowers" = {
        source = "${superpowers}/skills";
        recursive = true;
      };
      ".claude/commands/superpowers" = {
        source = "${superpowers}/commands";
        recursive = true;
      };
    };
  };
}
