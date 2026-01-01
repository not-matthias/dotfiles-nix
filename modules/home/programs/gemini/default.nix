{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.gemini;
in {
  options.programs.gemini = {
    enable = mkEnableOption "Gemini CLI configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      unstable.gemini-cli
    ];

    home.file = {
      ".gemini/settings.json" = {
        source = ./settings.json;
      };
      ".gemini/GEMINI.md" = {
        source = ../claude/AGENTS.md;
      };
    };
  };
}
