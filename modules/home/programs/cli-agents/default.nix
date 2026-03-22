{
  config,
  lib,
  pkgs,
  ...
}: let
  anyCliAgentEnabled =
    builtins.any (agent: agent.enable or false) (builtins.attrValues config.programs.cli-agents);
in {
  imports = [
    ./agent-browser/default.nix
    ./claude/default.nix
    ./codex/default.nix
    ./gemini/default.nix
    ./hermes/default.nix
    ./opencode/default.nix
    ./amp/default.nix
    ./pi-mono/default.nix
  ];

  config = lib.mkIf anyCliAgentEnabled {
    home.packages = with pkgs; [
      ast-grep
      rizin
      ghidra-cli
      rtk
    ];

    # Exclude shared agent scratch/working files from git by default
    programs.git.ignores = lib.mkAfter [".agents"];
  };
}
