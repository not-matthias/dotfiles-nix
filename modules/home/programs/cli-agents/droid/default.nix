{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.droid;
  sharedSkillsFlat = import ../shared/skills.nix {inherit lib pkgs;};
in {
  options.programs.cli-agents.droid = {
    enable = mkEnableOption "Factory Droid CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.droid];

    programs.fish.shellAbbrs = {
      "dr" = "droid";
    };

    home.file = {
      ".factory/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".factory/skills" = {
        source = sharedSkillsFlat;
        recursive = true;
      };
    };
  };
}
