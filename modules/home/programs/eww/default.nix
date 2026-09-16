{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.eww;
  colors = config.lib.stylix.colors.withHashtag;
  niriState = import ./modules/niri-state.nix {inherit pkgs;};
  aiUsage = import ./modules/ai-usage.nix {inherit pkgs;};
  dnd = import ./modules/dnd.nix {inherit pkgs;};
  volume = import ./modules/volume.nix {inherit pkgs;};
  battery = import ./modules/battery.nix {inherit pkgs;};
  idleInhibit = import ./modules/idle-inhibit.nix {inherit pkgs;};
  flashgenWord = import ./modules/flashgen-word.nix {
    inherit pkgs;
    cfg = cfg.flashgenWordOfHour;
  };
  flashgenEnabled = cfg.flashgenWordOfHour.enable;
  flashgenCommand =
    if flashgenEnabled
    then "flashgen-word-of-hour"
    else "${pkgs.jq}/bin/jq -nc '{text:\"\",tooltip:\"\"}'";
  flashgenOpenCommand =
    if flashgenEnabled
    then "flashgen-word-of-hour --open"
    else ":";
  niriStateCommand = "${niriState}/bin/eww-niri-state";
  calendarToggle = pkgs.writeShellScriptBin "eww-calendar-toggle" ''
    set -euo pipefail

    screen="$1"
    opened="$(${pkgs.eww}/bin/eww active-windows)"
    case "$opened" in
      *"calendar-$screen:"*) reopen=false ;;
      *) reopen=true ;;
    esac

    # One calendar at a time, no matter which bar spawned the open one.
    ${pkgs.gnused}/bin/sed -n 's/^\(calendar-[^:]*\):.*/\1/p' <<< "$opened" | while IFS= read -r window; do
      ${pkgs.eww}/bin/eww close "$window"
    done

    if [ "$reopen" = true ]; then
      ${pkgs.eww}/bin/eww open calendar_popup --id "calendar-$screen" --screen "$screen"
    fi
  '';
  calendarToggleCommand = "${calendarToggle}/bin/eww-calendar-toggle";
  producerPackages =
    [
      niriState
      aiUsage.claudeScript
      aiUsage.codexScript
      aiUsage.antigravityScript
      dnd
      volume
      battery
      idleInhibit.status
    ]
    ++ lib.optional flashgenEnabled flashgenWord.script;
  runtimePackages =
    [
      pkgs.bash
      pkgs.coreutils
      pkgs.curl
      pkgs.dunst
      pkgs.eww
      pkgs.gawk
      pkgs.jq
      pkgs.niri
      pkgs.pavucontrol
      pkgs.systemd
      pkgs.wireplumber
      pkgs.wlinhibit
    ]
    ++ producerPackages;
  runtimePath = lib.makeBinPath runtimePackages;
  syncBars = pkgs.writeShellScriptBin "eww-topbar-sync" ''
    set -euo pipefail

    outputs="$(${pkgs.niri}/bin/niri msg --json outputs | ${pkgs.jq}/bin/jq -r 'keys[]')"
    if [ -z "$outputs" ]; then
      echo "Niri reported no outputs" >&2
      exit 1
    fi

    # Eww drops a window when its output disappears, so reopening the missing
    # ids is all a hotplug needs.
    opened="$(${pkgs.eww}/bin/eww active-windows)"
    while IFS= read -r output; do
      case "$opened" in
        *"topbar-$output:"*) ;;
        *) ${pkgs.eww}/bin/eww open topbar --id "topbar-$output" --screen "$output" ;;
      esac
    done <<< "$outputs"
  '';
  launcher = pkgs.writeShellScriptBin "eww-topbar-launch" ''
    set -euo pipefail

    for _ in $(${pkgs.coreutils}/bin/seq 1 50); do
      if ${pkgs.eww}/bin/eww ping >/dev/null 2>&1; then
        exec ${syncBars}/bin/eww-topbar-sync
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done
    echo "Eww daemon did not answer ping" >&2
    exit 1
  '';
  monitorWatch = pkgs.writeShellScriptBin "eww-topbar-monitor-watch" ''
    set -euo pipefail

    # Niri has no output-hotplug event; reassigned workspaces are the signal.
    # The stream is read through process substitution so a failing sync exits
    # this script instead of only the subshell a pipeline would create.
    while IFS= read -r event; do
      case "$event" in
        "Workspaces changed"*) ${syncBars}/bin/eww-topbar-sync ;;
      esac
    done < <(${pkgs.niri}/bin/niri msg event-stream)
  '';
in {
  options.programs.eww.flashgenWordOfHour = {
    enable = (lib.mkEnableOption "Flashgen passive word-of-the-hour Eww widget") // {default = true;};

    dbPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Documents/technical/git/flashgen/data/sinostack.db";
      description = "Mutable Flashgen SQLite database path.";
    };

    hskLevel = lib.mkOption {
      type = lib.types.ints.between 1 9;
      default = 3;
      description = "HSK level to rotate through.";
    };

    hskVersion = lib.mkOption {
      type = lib.types.enum [2 3];
      default = 3;
      description = "HSK version to read from the Flashgen database.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.eww = {
      package = pkgs.eww;
      yuckConfig =
        builtins.replaceStrings
        ["@FLASHGEN_COMMAND@" "@FLASHGEN_OPEN_COMMAND@" "@NIRI_STATE_COMMAND@" "@CALENDAR_TOGGLE@"]
        [flashgenCommand flashgenOpenCommand niriStateCommand calendarToggleCommand]
        (builtins.readFile ./eww.yuck);
      scssConfig = ''
        $base00: ${colors.base00};
        $base01: ${colors.base01};
        $base02: ${colors.base02};
        $base05: ${colors.base05};
        $base08: ${colors.base08};
        $base09: ${colors.base09};
        $base0A: ${colors.base0A};
        ${builtins.readFile ./eww.scss}
      '';
    };

    home.packages = [pkgs.eww pkgs.pavucontrol pkgs.wlinhibit] ++ producerPackages;

    systemd.user.services = {
      eww-idle-inhibit = idleInhibit.service;
      eww.Service = {
        Environment = "PATH=${runtimePath}";
        ExecStartPost = "${launcher}/bin/eww-topbar-launch";
        Restart = "on-failure";
        RestartSec = 1;
      };
      eww-topbar-monitors = {
        Unit = {
          Description = "Reopen Eww topbars when Niri outputs change";
          PartOf = ["graphical-session.target"];
          After = ["eww.service"];
        };
        Service = {
          Environment = "PATH=${runtimePath}";
          ExecStart = "${monitorWatch}/bin/eww-topbar-monitor-watch";
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
