# https://github.com/Daru-san/SnowyDots/tree/master/modules/home/wayland/niri/config
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
  imports = [./home/default.nix];

  options.desktop.niri = {
    enable = mkEnableOption "Enable Niri scrollable-tiling Wayland compositor";
    package = mkOption {
      type = types.package;
      default = flakes.niri.packages.${pkgs.system}.niri-stable;
      example = flakes.niri.packages.${pkgs.system}.niri-unstable;
      description = "Which niri package to use (niri-stable or niri-unstable)";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = ["https://niri.cachix.org"];
      trusted-public-keys = ["niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="];
    };
    nixpkgs.overlays = [flakes.niri.overlays.niri];

    stylix.enable = true;

    # Enable UWSM for proper systemd session management
    programs.uwsm = {
      enable = true;
      waylandCompositors.niri = {
        prettyName = "Niri";
        comment = "Niri - scrollable-tiling Wayland compositor";
        binPath = "${cfg.package}/bin/niri-session";
      };
    };

    # Essential Wayland environment setup
    # FIXME: Do we need this?
    programs.xwayland.enable = true;

    environment = {
      variables = {
        XDG_CURRENT_DESKTOP = lib.mkDefault "niri";
        XDG_SESSION_TYPE = lib.mkDefault "wayland";
        XDG_SESSION_DESKTOP = lib.mkDefault "niri";
      };

      sessionVariables = {
        CLUTTER_BACKEND = "wayland";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        DISPLAY = ":0";
      };

      # Essential packages for basic niri functionality
      systemPackages = with pkgs; [
        wofi-emoji # Emoji picker (Ctrl+Period)
        wl-clipboard # Wayland clipboard utilities
        wlr-randr # Display configuration
        wl-mirror # Screen mirroring (use with `wl-present mirror eDP-1`)
        alsa-utils # Volume control (provides amixer)
        brightnessctl # Brightness control
        playerctl # Media control
        nemo-with-extensions # File manager (Alt+E)
        xwayland-satellite # XWayland integration
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
        config = {
          common.default = "*";
          niri = {
            default = ["gnome" "gtk"];
            "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
          };
        };
      };
    };

    # Security services
    security = {
      polkit.enable = true;
      pam.services = {
        login.enableGnomeKeyring = true;
        swaylock = {
          text = ''
            auth include login
          '';
          enableGnomeKeyring = true;
        };
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
