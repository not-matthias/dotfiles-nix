{
  pkgs,
  lib,
  config,
  flakes,
  ...
}:
with lib; let
  cfg = config.desktop.niri;
in {
  imports = [flakes.niri.nixosModules.niri];

  options.desktop.niri = {
    enable = mkEnableOption "Enable Niri scrollable-tiling Wayland compositor";
    package = mkOption {
      type = types.package;
      default = niri.packages.${pkgs.system}.niri-stable;
      example = niri.packages.${pkgs.system}.niri-unstable;
      description = "Which niri package to use (niri-stable or niri-unstable)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = cfg.package;
    };

    # Enable niri-flake binary cache for faster builds
    niri-flake.cache.enable = true;

    # Essential Wayland environment setup
    programs.xwayland.enable = true;

    environment = {
      sessionVariables = {
        # Enable Wayland for Electron/CEF apps
        NIXOS_OZONE_WL = "1";
      };

      # Essential packages for basic niri functionality
      systemPackages = with pkgs; [
        alacritty # Terminal (Super+T)
        fuzzel # Application launcher (Super+D)
        wl-clipboard # Wayland clipboard utilities
        swaylock # Screen locker
        wlr-randr # Display configuration
      ];
    };

    # System services required for proper Wayland desktop functionality
    services = {
      libinput.enable = true;
      dbus.enable = true;
      gvfs.enable = true;
      gnome = {
        sushi.enable = true;
        gnome-keyring.enable = true;
      };
    };

    # XDG Desktop Portal configuration for app integration
    xdg = {
      autostart.enable = true;
      portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        config.common.default = "*";
      };
    };

    # Security services
    security = {
      polkit.enable = true;
      pam.services.swaylock = {
        text = ''
          auth include login
        '';
      };
    };

    # Power management
    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=no
      AllowSuspendThenHibernate=no
      AllowHybridSleep=yes
    '';
  };
}
