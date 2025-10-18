{
  config,
  lib,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.claude;
in {
  options.programs.claude = {
    enable = mkEnableOption "Claude Code configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with unstable; [
      claude-code
    ];

    home.file = {
      ".claude/CLAUDE.md" = {
        source = ./CLAUDE.md;
      };
      ".claude/settings.json" = {
        source = ./settings.json;
      };
      ".claude/commands" = {
        source = ./commands;
        recursive = true;
      };
    };
  };
}
