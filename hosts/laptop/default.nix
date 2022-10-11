{
  config,
  pkgs,
  user,
  ...
}: {
  imports =
    [(import ./hardware-configuration.nix)]
    ++ [(import ./configuration.nix)];

  # TODO: Window Manager, Docker, Hardware Devices (Bluetooth)

  programs = {
    dconf.enable = true;
    light.enable = true;
  };
}
