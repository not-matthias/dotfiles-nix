{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.ghidra;
  ghidra_dir = ".config/ghidra/${pkgs.ghidra.distroPrefix}";
in {
  options.programs.ghidra = {
    enable = lib.mkEnableOption "Ghidra reverse engineering platform";

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of Ghidra extensions to enable";
      example = ["ret-sync" "findcrypt"];
    };

    preferences = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        GhidraShowWhatsNew = "false";
        "SHOW.HELP.NAVIGATION.AID" = "true";
        SHOW_TIPS = "false";
        USER_AGREEMENT = "ACCEPT";
      };
      description = "Ghidra preferences to set";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (
        pkgs.writeShellScriptBin "ghidra" ''
          exec env _JAVA_AWT_WM_NONREPARENTING=1 ${
            if cfg.extensions != []
            then (pkgs.ghidra.withExtensions (p: map (ext: p.${ext}) cfg.extensions))
            else pkgs.ghidra
          }/bin/ghidra "$@"
        ''
      )
    ];

    home.file."${ghidra_dir}/preferences".text = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "${k}=${v}") cfg.preferences
    );
  };
}
