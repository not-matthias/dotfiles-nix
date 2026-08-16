{
  config,
  lib,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.claude;

  sharedSkills = ../shared/skills;
  # Relative paths of every directory under sharedSkills containing SKILL.md, any depth
  findSkills = dir: rel:
    flatten (mapAttrsToList (
      name: type: let
        rel' =
          if rel == ""
          then name
          else "${rel}/${name}";
      in
        if type != "directory"
        then []
        else if pathExists (dir + "/${name}/SKILL.md")
        then [rel']
        else findSkills (dir + "/${name}") rel'
    ) (builtins.readDir dir));
  # Top-level skills already sit at $out root after cp; only nested ones need flat links
  nestedSkills = filter (path: path != baseNameOf path) (findSkills sharedSkills "");
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
