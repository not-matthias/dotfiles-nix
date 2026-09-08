{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.idasql;
in {
  options.programs.idasql = {
    enable = mkEnableOption "IDASQL";
    package = mkOption {
      type = types.package;
      default = pkgs.idasql;
      defaultText = literalExpression "pkgs.idasql";
      description = "IDASQL package to install.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.ida-pro
      cfg.package
    ];

    home.file = {
      ".idapro/plugins/idasql.so".source = "${cfg.package}/lib/ida/plugins/idasql.so";
      ".idapro/plugins/ida-plugin.json".source = "${cfg.package}/lib/ida/plugins/ida-plugin.json";
    };

    programs.cli-agents.programSkills.idasql = ./skill;
  };
}
