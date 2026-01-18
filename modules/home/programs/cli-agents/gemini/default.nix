{
  config,
  lib,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.gemini;
in {
  options.programs.cli-agents.gemini = {
    enable = mkEnableOption "Gemini CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      unstable.gemini-cli
    ];

    home.file = {
      # Gemini-specific settings
      ".gemini/settings.json" = {
        source = ./settings.json;
      };

      # Shared instruction files (Gemini uses AGENTS.md via contextFileName in settings)
      ".gemini/GEMINI.md" = {
        source = ../shared/AGENTS.md;
      };
    };
  };
}
