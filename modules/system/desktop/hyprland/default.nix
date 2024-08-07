# https://codeberg.org/totoroot/dotfiles/src/branch/main/modules/desktop/hyprland.nix
# https://github.com/MatthiasBenaets/nixos-config/blob/1a31b9eae7e7349b52488476ca5642f1997cbdb1/modules/desktop/hyprland/default.nix
# https://github.com/linuxmobile/kaku/blob/main/home/wayland/default.nix
#
# Nvidia related stuff:
# https://old.reddit.com/r/hyprland/comments/zulmrz/tutorial_on_hyprland_setup_with_nvidiaintel/
# https://wiki.hyprland.org/Nvidia/
#
{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.desktop.hyprland;
in {
  imports = [./home/default.nix];

  options.desktop.hyprland = {
    enable = mkEnableOption "Enable Hyprland";
    useNvidia = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether to use NVIDIA for rendering";
    };
  };

  # FIXME: Conditionally import this
  config = lib.mkIf cfg.enable {
    programs = {
      hyprland.enable = true;
      xwayland.enable = true;
    };

    environment = {
      loginShellInit = ''
        if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
         exec dbus-launch Hyprland
        fi
      '';
      variables = {
        # Workaround for Nvidia issues
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";

        LIBVA_DRIVER_NAME =
          if cfg.useNvidia
          then "nvidia"
          else "";
        GBM_BACKEND =
          if cfg.useNvidia
          then "nvidia-drm"
          else "";
        __GLX_VENDOR_LIBRARY_NAME =
          if cfg.useNvidia
          then "nvidia"
          else "";
      };
      sessionVariables = {
        # With NixOS, you can also try setting the NIXOS_OZONE_WL environment variable to 1,
        # which should automatically configure Electron / CEF apps to run with native Wayland for you.
        NIXOS_OZONE_WL = "1";
      };
    };

    environment.systemPackages = with pkgs; [
      swaylock
      wl-clipboard
      wlr-randr

      # TODO: https://github.com/ryan4yin/nix-config/blob/e39b79c5085a3555a754972ca88f5451f82638f4/modules/nixos/hyprland.nix#L70-L94
    ];

    services = {
      dbus.enable = true;
      displayManager.defaultSession = "hyprland";
      xserver = {
        enable = true;
        displayManager = {
          gdm = {
            enable = true;
            wayland = true;
          };
        };
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        # xdg-desktop-portal-hyprland is automatically pulled by flake
      ];

      config.common.default = "*";
    };

    security.pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };

    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=no
      AllowSuspendThenHibernate=no
      AllowHybridSleep=yes
    '';

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };
}
