{
  config,
  lib,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.claude;

  sharedSkills = ../shared/skills;
  groups = attrNames (filterAttrs (
    name: type:
      type == "directory" && !pathExists (sharedSkills + "/${name}/SKILL.md")
  ) (builtins.readDir sharedSkills));
  nestedSkills = flatten (map (
      group: let
        groupDir = sharedSkills + "/${group}";
        skills = attrNames (filterAttrs (_name: type: type == "directory") (builtins.readDir groupDir));
      in
        map (skill: "${group}/${skill}") skills
    )
    groups);
  claudeSkills = unstable.runCommand "claude-skills" {} ''
    mkdir $out
    cp -rT ${sharedSkills} $out
    ${concatMapStrings (
        path: "ln -s ${path} $out/${baseNameOf path}\n"
      )
      nestedSkills}
  '';
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
      # CLAUDE_CODE_AUTO_COMPACT_WINDOW = "400000";
      # CLAUDE_CODE_EFFORT_LEVEL = "medium";
    };

    home.file = {
      ".claude/CLAUDE.md" = {
        source = ../shared/AGENTS.md;
      };
      ".claude/skills" = {
        source = claudeSkills;
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
