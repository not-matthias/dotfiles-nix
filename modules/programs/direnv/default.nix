{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # enableFishIntegration = true;
  };
}
