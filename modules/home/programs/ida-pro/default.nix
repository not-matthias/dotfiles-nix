{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.ida-pro;
in {
  options.programs.ida-pro.enable = mkEnableOption "IDA Pro agent skills";

  config = mkIf cfg.enable {
    programs.cli-agents.programSkills = {
      "ida-domain-api" = ./skills/ida-domain-api;
      "ida-plugin-development" = ./skills/ida-plugin-development;
      "package-ida-plugin" = ./skills/package-ida-plugin;
    };
  };
}
