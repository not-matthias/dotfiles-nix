{
  config,
  lib,
  ...
}: let
  cfg = config.programs.nix-ld;
in {
  config = lib.mkIf cfg.enable {
    # Placeholder in case we want to configure the nix-ld libraries here
  };
}
