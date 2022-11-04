# https://codeberg.org/totoroot/dotfiles/src/branch/main/modules/desktop/hyprland.nix
{
  pkgs,
  hyprland,
  ...
}: {
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  environment = {
    loginShellInit = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
      fi
    ''; # Will automatically open sway when logged into tty1
    systemPackages = with pkgs; [
      xdg-desktop-portal-wlr
    ];
  };

  programs = {
    hyprland = {
      enable = true;
      package = hyprland.packages.${pkgs.system}.default;
    };
    xwayland.enable = true;
  };
}
