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
    useIntel = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = "Whether to use Intel for rendering";
    };
  };

  # FIXME: Conditionally import this
  config = lib.mkIf cfg.enable {
    programs = {
      hyprland = {
        enable = true;
        package = pkgs.hyprland;
        withUWSM = true;
      };
      xwayland.enable = true;
    };

    environment = {
      loginShellInit = ''
        if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
            if uwsm check may-start && uwsm select; then
                exec uwsm start default
            fi
        fi
      '';
      variables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";

        AQ_DRM_DEVICES = "/dev/dri/card1";
        LIBVA_DRIVER_NAME =
          if cfg.useNvidia
          then "nvidia"
          else if cfg.useIntel
          then "iHD"
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
    ];

    services = {
      libinput.enable = true;
      dbus.enable = true;
      gvfs.enable = true;
      gnome = {
        sushi.enable = true;
        gnome-keyring.enable = true;
      };
    };

    xdg = {
      autostart.enable = true;
      portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
        ];

        config.common.default = "*";
      };
    };

    security = {
      polkit.enable = true;
      pam.services.swaylock = {
        text = ''
          auth include login
        '';
      };
    };

    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=no
      AllowSuspendThenHibernate=no
      AllowHybridSleep=yes
    '';

    # services.hypridle.enable = true;
    # https://github.com/atimofeev/nixos-config/blob/e331eb04eb292e7f343bf18d57e3f29e3626b43c/home/desktop/hyprland/hyprpaper.nix
    # programs.hyprpaper.enable = true;
    # https://github.com/atimofeev/nixos-config/blob/e331eb04eb292e7f343bf18d57e3f29e3626b43c/home/desktop/hyprland/hyprlock.nix
    # programs.hyprlock.enable = true;

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };
}
