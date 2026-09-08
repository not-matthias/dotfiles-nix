{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: let
  anyCliAgentEnabled =
    builtins.any (agent: agent.enable or false) (builtins.attrValues (builtins.removeAttrs config.programs.cli-agents ["programSkills"]));
in {
  options.programs.cli-agents.programSkills = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    default = {};
    description = "Program-owned skill directories keyed by exposed skill name; values are directories containing SKILL.md.";
  };
  imports = [
    ./agent-browser/default.nix
    ./claude/default.nix
    ./codex/default.nix
    ./hermes/default.nix
    ./opencode/default.nix
    ./amp/default.nix
    ./pi-mono/default.nix
    ./oh-my-pi/default.nix
    ./herdr/default.nix
  ];

  config = lib.mkIf anyCliAgentEnabled {
    home.packages = with pkgs; [
      ast-grep
      rizin
      # ghidra-cli
      rtk
      unstable.gogcli
      jq
      mcporter
    ];

    # Exclude shared agent scratch/working files from git by default
    programs.git.ignores = lib.mkAfter [".agents"];
  };
}
