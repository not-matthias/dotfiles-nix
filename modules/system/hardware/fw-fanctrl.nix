{
  config,
  lib,
  unstable,
  ...
}: let
  # Import the fw-fanctrl module from unstable nixpkgs
  fwFanctrlModule = "${unstable.path}/nixos/modules/hardware/fw-fanctrl.nix";
in {
  imports = [
    fwFanctrlModule
  ];

  # Override the package to use unstable version
  config = lib.mkIf config.hardware.fw-fanctrl.enable {
    hardware.fw-fanctrl.package = lib.mkDefault unstable.fw-fanctrl;
    hardware.fw-fanctrl.ectoolPackage = lib.mkDefault unstable.fw-ectool;
  };
}
