{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.programs.steam;
in {
  config = lib.mkIf cfg.enable {
    # This has to be set by the user:
    # programs.steam.enable = true;

    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

    environment.systemPackages = with pkgs; [
      protonup-qt
      lutris

      wineWowPackages.stable
      winetricks
      obs-studio
    ];
  };
}
