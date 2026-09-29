{
  pkgs,
  osConfig ? {},
  lib,
  ...
}: let
  useNvidia = osConfig.hardware.nvidia.enable or false;
in {
  programs.btop = {
    enable = true;
    package = lib.mkIf useNvidia (pkgs.btop.override {cudaSupport = true;});
    settings = {
      color_theme = "desktop-current";
      save_config_on_exit = false;
      vim_keys = true;
    };
  };
}
