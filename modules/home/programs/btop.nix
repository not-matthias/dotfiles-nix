{
  pkgs,
  osConfig,
  lib,
  ...
}: let
  useNvidia = osConfig.hardware.nvidia.enable or false;
in {
  programs.btop = {
    enable = true;
    package = lib.mkIf useNvidia pkgs.btop.override {cudaSupport = true;};
    settings = {
      vim_keys = true;
    };
  };
}
