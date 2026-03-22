{
  lib,
  config,
  noctalia,
  ...
}:
with lib; let
  cfg = config.programs.noctalia;
in {
  imports = [noctalia.homeModules.default];

  options.programs.noctalia = {
    enable = mkEnableOption "Enable Noctalia desktop shell";
  };

  config = mkIf cfg.enable {
    programs.noctalia-shell = {
      enable = true;
      settings = {
        bar = {
          density = "compact";
          position = "right";
        };
        colorSchemes.predefinedScheme = "Monochrome";
        general = {
          radiusRatio = 0.2;
        };
      };
    };
  };
}
