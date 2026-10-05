{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.plannotator;
in {
  options.programs.plannotator.enable = lib.mkEnableOption "Plannotator plan and diff review";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.plannotator];

    home.file.".plannotator/config.json".text = builtins.toJSON {
      diffOptions = {
        expandUnchanged = false;
        defaultDiffType = "since-base";
        diffStyle = "split";
      };
    };
  };
}
