{
  config,
  lib,
  pkgs,
  unstable,
  ...
}: let
  cfg = config.hardware.fw-fanctrl;
  sched = cfg.schedule;
  # "22:00" -> "2200", comparable as a decimal number in test(1).
  toHHMM = t: lib.replaceStrings [":"] [""] t;
  reconcile = pkgs.writeShellApplication {
    name = "fw-fanctrl-schedule";
    runtimeInputs = [cfg.package];
    text = ''
      now=$(date +%H%M)
      from=${toHHMM sched.from}
      to=${toHHMM sched.to}
      if [ "$from" -gt "$to" ]; then
        # window wraps past midnight
        if [ "$now" -ge "$from" ] || [ "$now" -lt "$to" ]; then night=1; else night=0; fi
      else
        if [ "$now" -ge "$from" ] && [ "$now" -lt "$to" ]; then night=1; else night=0; fi
      fi
      if [ "$night" = 1 ]; then args=(use "${sched.strategy}"); else args=(reset); fi
      # The daemon opens its command socket in a thread shortly after exec.
      for _ in $(seq 10); do
        if fw-fanctrl "''${args[@]}"; then exit 0; fi
        sleep 1
      done
      exit 1
    '';
  };
in {
  options.hardware.fw-fanctrl.schedule = {
    enable = lib.mkEnableOption "switching to a quieter strategy during a nightly window";
    strategy = lib.mkOption {
      type = lib.types.str;
      default = "quiet";
      description = "Strategy to apply inside the window; outside it the host's defaultStrategy is restored.";
    };
    from = lib.mkOption {
      type = lib.types.strMatching "[0-9]{2}:[0-9]{2}";
      default = "22:00";
    };
    to = lib.mkOption {
      type = lib.types.strMatching "[0-9]{2}:[0-9]{2}";
      default = "09:00";
    };
  };

  # Override the package to use unstable version
  config = lib.mkIf cfg.enable {
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

    # Upstream only ships lazy/medium/agile/...; these are repo-local, so hosts
    # can select them by name.
    hardware.fw-fanctrl.config.strategies = {
      # Silence at idle without a throttling cliff: holds a low duty while the
      # machine is unloaded, then ramps to full before the thermal limit.
      night = {
        fanSpeedUpdateFrequency = 5;
        movingAverageInterval = 45;
        speedCurve = [
          {
            temp = 0;
            speed = 0;
          }
          {
            temp = 60;
            speed = 15;
          }
          {
            temp = 80;
            speed = 30;
          }
          {
            temp = 85;
            speed = 60;
          }
          {
            temp = 90;
            speed = 100;
          }
        ];
      };
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

    systemd.services.fw-fanctrl-schedule = lib.mkIf sched.enable {
      description = "Apply the fw-fanctrl time-of-day strategy";
      # `use` is in-memory only, so re-apply whenever the daemon restarts.
      after = ["fw-fanctrl.service"];
      wantedBy = ["fw-fanctrl.service" "timers.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe reconcile;
      };
    };

    systemd.timers.fw-fanctrl-schedule = lib.mkIf sched.enable {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*:00/15";
        Persistent = true;
      };
    };
  };
}
