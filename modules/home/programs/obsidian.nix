# See: https://help.obsidian.md/Extending+Obsidian/Obsidian+URI
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.obsidian;
in {
  options.programs.obsidian = {
    enable = lib.mkEnableOption "Obsidian with custom desktop entries";

    vaults = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          vaultName = lib.mkOption {
            type = lib.types.str;
            description = "The vault name to open (URL encoded if needed)";
          };
          desktopName = lib.mkOption {
            type = lib.types.str;
            description = "Display name for the desktop entry";
          };
          icon = lib.mkOption {
            type = lib.types.str;
            default = "obsidian";
            description = "Icon name for the desktop entry";
          };
        };
      });
      default = {};
      description = "Obsidian vaults to create desktop entries for";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [pkgs.obsidian]
      ++ (lib.mapAttrsToList (
          name: vault: let
            # Create a wrapper script that launches obsidian with the vault URL
            launcherScript = pkgs.writeShellScriptBin "obsidian-${name}" ''
              exec ${lib.getExe pkgs.obsidian} \
                --enable-features=UseOzonePlatform \
                --ozone-platform=wayland \
                "obsidian://open?vault=${vault.vaultName}"
            '';
          in
            pkgs.symlinkJoin {
              name = "obsidian-${name}-desktop";
              paths = [
                launcherScript
                (pkgs.makeDesktopItem {
                  name = "obsidian-${name}";
                  desktopName = vault.desktopName;
                  exec = "obsidian-${name}";
                  icon = vault.icon;
                  type = "Application";
                  categories = ["Office"];
                  comment = "Open ${vault.vaultName} vault in Obsidian";
                })
              ];
            }
        )
        cfg.vaults);
  };
}
