{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.claude;

  # Hook script to load AGENTS.md from the project repository
  loadAgentsMdScript = pkgs.writeShellScript "load-agents-md" (builtins.readFile ./scripts/load-agents-md.sh);
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
      # Shared instruction files
      ".claude/CLAUDE.md" = {
        source = ../shared/INSTRUCTIONS.md;
      };
      ".claude/AGENTS.md" = {
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

      # Claude-specific settings with hook script injected
      ".claude/settings.json" = {
        text =
          lib.strings.replaceStrings
          ["@load-agents-md-hook@"]
          ["${loadAgentsMdScript}"]
          (builtins.readFile ./settings.json);
      };
    };
  };
}
