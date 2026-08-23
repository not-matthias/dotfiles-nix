{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.lmstudio;
in {
  options.programs.lmstudio = {
    enable = lib.mkEnableOption "LM Studio";

    rocm = {
      enable = lib.mkEnableOption "the LM Studio ROCm runtime";

      vendorPath = lib.mkOption {
        type = lib.types.str;
        default = ".lmstudio/extensions/backends/vendor/linux-llama-rocm-vendor-v4";
        description = "Path relative to the home directory containing LM Studio's ROCm libraries.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (
        if cfg.rocm.enable
        then pkgs.lmstudio.override {rocmVendorPath = cfg.rocm.vendorPath;}
        else pkgs.lmstudio
      )
    ];

    home.sessionVariables = lib.mkIf cfg.rocm.enable {
      NIX_LD_LIBRARY_PATH = lib.concatStringsSep ":" [
        "/run/current-system/sw/share/nix-ld/lib"
        "${config.home.homeDirectory}/${cfg.rocm.vendorPath}"
      ];
    };
  };
}
