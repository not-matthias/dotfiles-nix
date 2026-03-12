{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.codex;
in {
  options.programs.cli-agents.codex = {
    enable = mkEnableOption "Codex CLI agent";
  };

  config = mkIf cfg.enable {
    programs.fish.shellAbbrs = {
      "cx" = "bunx @openai/codex@latest";
    };

    home.file = {
      ".codex/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".codex/commands" = {
        source = ../shared/commands;
        recursive = true;
      };
      ".codex/skills" = {
        source = ../shared/skills;
        recursive = true;
      };
      ".codex/config.toml" = {
        source = ./config.toml;
      };
    };
  };
}
