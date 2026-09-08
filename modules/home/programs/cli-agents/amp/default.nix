{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.amp;
  agentSkillsFlat = import ../shared/skills.nix {
    inherit lib pkgs;
    programSkills = config.programs.cli-agents.programSkills;
  };
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
        source = agentSkillsFlat;
        recursive = true;
      };
    };
  };
}
