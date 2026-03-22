{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.hermes;
in {
  options.programs.cli-agents.hermes = {
    enable = mkEnableOption "Hermes Agent CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.hermes-agent];

    programs.fish.shellAbbrs = {
      "ha" = "hermes";
    };

    # home.file.".hermes/config.yaml".source = ./config.yaml;
  };
}
