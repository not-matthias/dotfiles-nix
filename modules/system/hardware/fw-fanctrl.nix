{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: {
  # Override the package to use unstable version
  config = lib.mkIf config.hardware.fw-fanctrl.enable {
    # Keep a shell's Python package paths from shadowing this application's closure.
    hardware.fw-fanctrl.package = lib.mkDefault (pkgs.symlinkJoin {
      name = "fw-fanctrl";
      meta =
        unstable.fw-fanctrl.meta
        // {
          mainProgram = "fw-fanctrl";
        };
      paths = [unstable.fw-fanctrl];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/fw-fanctrl --unset PYTHONPATH
      '';
    });
    hardware.fw-fanctrl.ectoolPackage = lib.mkDefault unstable.fw-ectool;
  };
}
