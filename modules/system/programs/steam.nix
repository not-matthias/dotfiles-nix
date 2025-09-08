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
    programs.gamescope = {
      enable = true;
      capSysNice = true;
      args = [
        "--rt"
        "--expose-wayland"
      ];
    };

    environment.systemPackages = with pkgs; [
      protonup-qt
      lutris

      wineWowPackages.stable
      winetricks
    ];

    # Additional environment variables for gamescope
    environment.sessionVariables = {
      # Enable gamescope to use DRM backend properly
      GAMESCOPE_WAYLAND_DISPLAY = "wayland-0";
    };
  };
}
