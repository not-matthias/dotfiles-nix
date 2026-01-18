{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.pi-mono;
in {
  options.programs.cli-agents.pi-mono = {
    enable = mkEnableOption "Pi-Mono CLI agent";
  };

  config = mkIf cfg.enable {
    # Add fish alias for pi-mono
    programs.fish.shellAbbrs = {
      "pm" = "bunx @mariozechner/pi-coding-agent";
    };

    # Create config directory with shared instructions
    home.file = {
      ".pi-mono/INSTRUCTIONS.md" = {
        source = ../shared/INSTRUCTIONS.md;
      };
      ".pi-mono/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".pi-mono/commands" = {
        source = ../shared/commands;
        recursive = true;
      };
      ".pi-mono/skills" = {
        source = ../shared/skills;
        recursive = true;
      };
    };
  };
}
