{
  pkgs,
  config,
  lib,
  user,
  ...
}: let
  cfg = config.programs.steam;
  steamLibraryRoot = "/home/${user}/Games";
  steamLibraryPath = "${steamLibraryRoot}/SteamLibrary";
in {
  config = lib.mkIf cfg.enable {
    # This has to be set by the user:
    # programs.steam.enable = true;

    programs.steam = {
      package = pkgs.steam.override {
        extraPreBwrapCmds = ''
          mkdir -p ${lib.escapeShellArg steamLibraryPath}
        '';
        extraBwrapArgs = [
          "--bind"
          steamLibraryRoot
          steamLibraryRoot
        ];
      };
      gamescopeSession.enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [proton-ge-bin];
      extraPackages = with pkgs; [
        gamemode
        gamescope
        mangohud
        umu-launcher
      ];
      localNetworkGameTransfers.openFirewall = true;
      remotePlay.openFirewall = true;
    };

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
      protontricks
      lutris
      gamemode
      mangohud
      umu-launcher

      wineWowPackages.stable
      wineWowPackages.waylandFull
      winetricks

      # Vulkan tools and drivers
      vulkan-tools
      vulkan-loader
      vulkan-validation-layers
    ];

    hardware.steam-hardware.enable = true;

    systemd.tmpfiles.rules = [
      "d ${steamLibraryRoot} 0755 ${user} users -"
      "d ${steamLibraryPath} 0755 ${user} users -"
    ];

    # Additional environment variables for gamescope
    environment.sessionVariables = {
      # Enable gamescope to use DRM backend properly
      GAMESCOPE_WAYLAND_DISPLAY = "wayland-0";
    };
  };
}
