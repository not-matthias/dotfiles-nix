{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.codex;
  agentSkillsFlat = import ../shared/skills.nix {
    inherit lib pkgs;
    programSkills = config.programs.cli-agents.programSkills;
  };
in {
  options.programs.cli-agents.codex = {
    enable = mkEnableOption "Codex CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      unstable.codex
    ];

    programs.fish.shellAbbrs = {
      "cx" = "bunx @openai/codex@latest --yolo";
    };

    home.file = {
      ".codex/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".codex/skills" = {
        source = agentSkillsFlat;
        recursive = true;
      };
      ".codex/agents" = {
        source = ../shared/sub-agents;
        recursive = true;
      };
      #".codex/config.toml" = {
      #  source = ./config.toml;
      #};
    };
  };
}
