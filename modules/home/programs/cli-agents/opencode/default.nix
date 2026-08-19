{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.opencode;
  sharedSkillsFlat = import ../shared/skills.nix {inherit lib pkgs;};
in {
  options.programs.cli-agents.opencode = {
    enable = mkEnableOption "OpenCode CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [
      # bun add -g opencode-ai
      unstable.opencode
    ];

    programs.fish.shellAliases = {
      "oc" = "opencode";
    };

    home.file = {
      # Shared instruction files
      ".opencode/AGENTS.md" = {
        source = ../shared/AGENTS.md;
      };
      ".opencode/skills" = {
        source = sharedSkillsFlat;
        recursive = true;
      };

      # OpenCode configuration with auth plugins
      ".opencode/opencode.json" = {
        text = builtins.toJSON {
          "$schema" = "https://opencode.ai/config.json";
          "plugin" = [
            "opencode-antigravity-auth@latest"
            "opencode-gemini-auth@latest"
          ];
        };
      };
    };
  };
}
