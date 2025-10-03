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

    # TODO: Set for the user:
    # programs.lutris = {
    #   enable = true;
    #   package = unstable.lutris;
    #   protonPackages = with pkgs; [proton-ge-bin];
    #   winePackages = with pkgs; [
    #     wineWow64Packages.stable
    #     wineWowPackages.stagingFull
    #   ];
    #   extraPackages = with pkgs; [
    #     mangohud
    #     winetricks
    #     gamescope
    #     gamemode
    #     umu-launcher
    #   ];
    # };

    programs.gamemode = {
      enable = true;
      enableRenice = true;
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
      args = [
        "--rt"
        "--expose-wayland"
      ];
    };

    # Enable hardware accelerated graphics
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    environment.systemPackages = with pkgs; [
      protonup-qt
      gamemode

      wineWowPackages.stable
      wineWowPackages.waylandFull
      winetricks

      # Vulkan tools and drivers
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
    ];

    # Additional environment variables for gamescope
    environment.sessionVariables = {
      # Enable gamescope to use DRM backend properly
      GAMESCOPE_WAYLAND_DISPLAY = "wayland-0";
    };
  };
}
