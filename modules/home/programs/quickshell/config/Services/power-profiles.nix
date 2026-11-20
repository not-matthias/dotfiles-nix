{
  pkgs,
  # Absolute fw-fanctrl binary, empty when the host has no fan control.
  fanCommand,
  # auto-cpufreq is driven through the activated system path because the
  # passwordless sudo rule in modules/system/hardware/powersave.nix matches
  # exactly that path, not a store path.
  cpuCommand,
}: let
  # Interpolated store paths blow past the line length flake8 enforces.
  script = pkgs.writers.writePython3Bin "quickshell-power-profiles" {flakeIgnore = ["E501"];} ''
    import json
    import os
    import pickle
    import subprocess
    import sys

    FAN_COMMAND = ${builtins.toJSON fanCommand}
    CPU_COMMAND = ${builtins.toJSON cpuCommand}
    SUDO = "/run/wrappers/bin/sudo"

    # auto-cpufreq has no getter for its override, it only persists the
    # pickled governor name written by `auto-cpufreq --force`.
    CPU_OVERRIDE_STATE = "/var/run/override.pickle"
    CPU_FORCE = {
        "auto": "reset",
        "powersave": "powersave",
        "performance": "performance",
    }

    CPUFREQ = "/sys/devices/system/cpu/cpu0/cpufreq"
    POWER_SUPPLY = "/sys/class/power_supply"


    def read_file(path):
        try:
            with open(path) as handle:
                return handle.read().strip()
        except OSError:
            return ""


    def on_ac():
        try:
            names = os.listdir(POWER_SUPPLY)
        except OSError:
            return False
        for name in names:
            if read_file(f"{POWER_SUPPLY}/{name}/type") != "Mains":
                continue
            if read_file(f"{POWER_SUPPLY}/{name}/online") == "1":
                return True
        return False


    def fan_state():
        if not FAN_COMMAND:
            return {"available": False}
        command = [FAN_COMMAND, "--output-format", "JSON", "print", "all"]
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=5,
                check=True,
            )
            data = json.loads(result.stdout)
        except (OSError, subprocess.SubprocessError, ValueError):
            return {"available": False}
        if data.get("status") != "success":
            return {"available": False}
        return {
            "available": True,
            "strategy": data.get("strategy", ""),
            "speed": data.get("speed", 0),
            "temperature": data.get("effectiveTemperature", 0),
        }


    def cpu_override():
        try:
            with open(CPU_OVERRIDE_STATE, "rb") as handle:
                override = pickle.load(handle)
        except (OSError, EOFError, ValueError, pickle.PickleError):
            return "auto"
        return override if override in CPU_FORCE else "auto"


    def cpu_state():
        if not CPU_COMMAND:
            return {"available": False}
        return {
            "available": True,
            "mode": cpu_override(),
            "governor": read_file(f"{CPUFREQ}/scaling_governor"),
            "onAc": on_ac(),
        }


    def set_fan(strategy):
        if not FAN_COMMAND:
            return 1
        return subprocess.run([FAN_COMMAND, "use", strategy]).returncode


    def set_cpu(mode):
        force = CPU_FORCE.get(mode)
        if not CPU_COMMAND or force is None:
            return 1
        command = [SUDO, "-n", CPU_COMMAND, "--force", force]
        return subprocess.run(command).returncode


    def main(argv):
        if argv == ["get"]:
            state = {"fan": fan_state(), "cpu": cpu_state()}
            print(json.dumps(state, separators=(",", ":")), flush=True)
            return 0
        if len(argv) == 2 and argv[0] == "fan":
            return set_fan(argv[1])
        if len(argv) == 2 and argv[0] == "cpu":
            return set_cpu(argv[1])
        print(
            "usage: quickshell-power-profiles "
            "get | fan <strategy> | cpu <mode>",
            file=sys.stderr,
        )
        return 2


    sys.exit(main(sys.argv[1:]))
  '';
in {
  inherit script;
}
