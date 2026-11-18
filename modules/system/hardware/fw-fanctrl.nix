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

    # Upstream only ships lazy/medium/agile/...; these four are repo-local, so hosts
    # can select them by name.
    hardware.fw-fanctrl.config.strategies = {
      silent = {
        fanSpeedUpdateFrequency = 5;
        movingAverageInterval = 45;
        speedCurve = [
          {
            temp = 0;
            speed = 30;
          }
          {
            temp = 100;
            speed = 30;
          }
        ];
      };
      quiet = {
        fanSpeedUpdateFrequency = 5;
        movingAverageInterval = 45;
        speedCurve = [
          {
            temp = 0;
            speed = 0;
          }
          {
            temp = 45;
            speed = 0;
          }
          {
            temp = 55;
            speed = 15;
          }
          {
            temp = 65;
            speed = 35;
          }
          {
            temp = 75;
            speed = 40;
          }
          {
            temp = 80;
            speed = 45;
          }
          {
            temp = 90;
            speed = 50;
          }
        ];
      };
      perf = {
        fanSpeedUpdateFrequency = 2;
        movingAverageInterval = 5;
        speedCurve = [
          {
            temp = 0;
            speed = 15;
          }
          {
            temp = 45;
            speed = 15;
          }
          {
            temp = 55;
            speed = 30;
          }
          {
            temp = 65;
            speed = 50;
          }
          {
            temp = 75;
            speed = 75;
          }
          {
            temp = 80;
            speed = 100;
          }
        ];
      };
      ultra = {
        fanSpeedUpdateFrequency = 2;
        movingAverageInterval = 5;
        speedCurve = [
          {
            temp = 0;
            speed = 15;
          }
          {
            temp = 45;
            speed = 15;
          }
          {
            temp = 55;
            speed = 75;
          }
          {
            temp = 65;
            speed = 90;
          }
          {
            temp = 75;
            speed = 90;
          }
          {
            temp = 80;
            speed = 100;
          }
        ];
      };
    };
  };
}
