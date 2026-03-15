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
    ./opencode/default.nix
    ./amp/default.nix
    ./pi-mono/default.nix
  ];

  config = lib.mkIf anyCliAgentEnabled {
    home.packages = with pkgs; [
      ast-grep
      rizin
      ghidra-cli
    ];
  };
}
