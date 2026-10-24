{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.worktrunk;
in {
  options.programs.worktrunk.enable = lib.mkEnableOption "Worktrunk git worktree manager";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.worktrunk];

    programs.fish = {
      # Shell integration lets `wt switch` change the current directory.
      interactiveShellInit = ''
        ${lib.getExe pkgs.worktrunk} config shell init fish | source
      '';
      shellAbbrs = {
        "wts" = "wt switch";
        "wtsc" = "wt switch --create";
      };
    };
  };
}
