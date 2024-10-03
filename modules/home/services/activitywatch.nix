# References:
# - https://github.com/QuentinI/dotnix/blob/dfc55407f3d99c3a46f80ba74052975ea693d548/modules/services/activitywatch.nix#L5
# - https://github.com/meain/dotfiles/blob/master/home-manager/.config/home-manager/home.nix#L343-L366
# - https://stackoverflow.com/a/58244114
# - https://unix.stackexchange.com/questions/564443/what-does-restart-on-abort-mean-in-a-systemd-service
# - https://discourse.nixos.org/t/nixos-22-11-systemd-user-services-dont-start-automatically-but-global-ones-do/24809
# - https://github.com/BhasherBEL/dotfiles-nix/blob/2ec5624c323ed4e2635a643311f92576519a25a6/home/shared/pc/apps/desktop/activitywatch.nix#L13
# - https://github.com/foo-dogsquared/nixos-config/blob/8e7a3e6277362d4830b8b13bb8aa02bc7ae5ca6b/configs/home-manager/foo-dogsquared/modules/setups/desktop.nix#L39
{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.services.activitywatch;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      aw-server-rust
      aw-watcher-afk
      aw-watcher-window
      aw-watcher-window-wayland
    ];

    services.activitywatch = {
      # Note: This will be set by the user of the module.
      # enable = true;
      package = pkgs.aw-server-rust;
      watchers = {
        aw-watcher-afk.package = pkgs.activitywatch;
        aw-watcher-window.package = pkgs.activitywatch;
        aw-watcher-window-wayland.package = pkgs.activitywatch;
      };
    };
  };
}
