{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.binary-ninja;
  desiredSettings = builtins.toJSON {
    "network.enableUpdates" = false;
  };
  settingsFile = pkgs.writeText "binaryninja-settings.json" desiredSettings;
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
    home.packages = [cfg.package] ++ cfg.extensions;

    home.activation.binaryNinjaSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      target="$HOME/.binaryninja/settings.json"
      if [[ -e "$target" && ! -L "$target" ]]; then
        temporary="$target.tmp"
        ${pkgs.jq}/bin/jq --argjson desired '${desiredSettings}' '. * $desired' "$target" > "$temporary"
        $DRY_RUN_CMD install -m 0644 "$temporary" "$target"
        $DRY_RUN_CMD rm -f "$temporary"
      else
        $DRY_RUN_CMD rm -f "$target"
        $DRY_RUN_CMD install -Dm 0644 ${settingsFile} "$target"
      fi
    '';

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
