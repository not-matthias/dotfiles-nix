# https://codeberg.org/totoroot/dotfiles/src/branch/main/modules/desktop/hyprland.nix
# https://github.com/MatthiasBenaets/nixos-config/blob/1a31b9eae7e7349b52488476ca5642f1997cbdb1/modules/desktop/hyprland/default.nix
# https://github.com/linuxmobile/kaku/blob/main/home/wayland/default.nix
{
  pkgs,
  hyprland,
  system,
  ...
}: {
  imports = [./home/default.nix];

  programs = {
    hyprland = {
      enable = true;
      package = hyprland.packages.${pkgs.system}.default;
    };

    xwayland.enable = true;
  };

  environment = {
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
       exec dbus-launch Hyprland
      fi
    '';
    variables = {
      #WLR_NO_HARDWARE_CURSORS="1";         # Possible variables needed in vm
      #WLR_RENDERER_ALLOW_SOFTWARE="1";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };
    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };
  };

  environment.systemPackages = with pkgs; [
    gnome.nautilus

    swaylock
    wl-clipboard
    wlr-randr

    # TODO: https://github.com/ryan4yin/nix-config/blob/e39b79c5085a3555a754972ca88f5451f82638f4/modules/nixos/hyprland.nix#L70-L94
  ];

  services = {
    xserver = {
      enable = true;
      displayManager = {
        defaultSession = "hyprland";
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
}
