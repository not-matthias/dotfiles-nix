{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.programs.swaylock;
in {
  config = lib.mkIf cfg.enable {
    programs.swaylock = {
      package = pkgs.swaylock-effects;
      settings = {
        # Allow both fingerprint and password authentication
        auth-method = "both";
        # Show text prompt for password fallback
        show-failed-attempts = true;
      };
    };
  };
}
