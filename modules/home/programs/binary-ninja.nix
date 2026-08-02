{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.binary-ninja;
in {
  options.programs.binary-ninja = {
    enable = lib.mkEnableOption "Binary Ninja reverse engineering platform";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.binary-ninja;
      description = "The Binary Ninja package to use";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Packages providing plugins under $out/lib/binaryninja/plugins";
      example = lib.literalExpression "[pkgs.binja-wasm]";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    # Keep this directory writable because Binary Ninja stores plugin manager state here.
    home.file.".binaryninja/plugins" = lib.mkIf (cfg.extensions != []) {
      source = pkgs.symlinkJoin {
        name = "binaryninja-plugins";
        paths = map (ext: "${ext}/lib/binaryninja/plugins") cfg.extensions;
      };
      recursive = true;
    };
  };
}
