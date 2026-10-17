{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.quickshellBar;
  flashgen = import ./config/Components/Flashgen/default.nix {
    inherit pkgs;
    cfg = cfg.flashgenWordOfHour;
  };
  aiUsage = import ./config/Components/AiUsage/default.nix {inherit pkgs;};
  idleInhibit = import ./config/Components/IdleInhibit/default.nix {inherit pkgs;};
  statusBridge = import ./config/Services/status-bridge.nix {inherit pkgs;};

  flashgenEnabled = cfg.flashgenWordOfHour.enable;
  flashgenFallback = pkgs.writeShellScriptBin "quickshell-flashgen-disabled" ''
    exec ${pkgs.jq}/bin/jq -nc '{text:"",tooltip:""}'
  '';
  flashgenCommand =
    if flashgenEnabled
    then "${flashgen.script}/bin/flashgen-word-of-hour"
    else "${flashgenFallback}/bin/quickshell-flashgen-disabled";

  producerPackages =
    [
      aiUsage.claudeScript
      aiUsage.codexScript
      aiUsage.antigravityScript
      statusBridge.bridge
    ]
    ++ lib.optionals flashgenEnabled [flashgen.script]
    ++ lib.optionals (!flashgenEnabled) [flashgenFallback];

  commands = {
    flashgen = flashgenCommand;
    claudeUsage = "${aiUsage.claudeScript}/bin/quickshell-claude-usage";
    codexUsage = "${aiUsage.codexScript}/bin/quickshell-codex-usage";
    antigravityUsage = "${aiUsage.antigravityScript}/bin/quickshell-antigravity-usage";
    statusBridge = "${statusBridge.bridge}/bin/quickshell-status-bridge";
    pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
    dunstctl = "${pkgs.dunst}/bin/dunstctl";
    niri = "${pkgs.niri}/bin/niri";
    systemctl = "${pkgs.systemd}/bin/systemctl";
  };
  commandsFile = pkgs.writeText "quickshell-commands.qml" ''
    pragma Singleton

    import QtQml

    QtObject {
        readonly property string flashgen: ${builtins.toJSON commands.flashgen}
        readonly property string claudeUsage: ${builtins.toJSON commands.claudeUsage}
        readonly property string codexUsage: ${builtins.toJSON commands.codexUsage}
        readonly property string antigravityUsage: ${builtins.toJSON commands.antigravityUsage}
        readonly property string statusBridge: ${builtins.toJSON commands.statusBridge}
        readonly property string pavucontrol: ${builtins.toJSON commands.pavucontrol}
        readonly property string dunstctl: ${builtins.toJSON commands.dunstctl}
        readonly property string niri: ${builtins.toJSON commands.niri}
        readonly property string systemctl: ${builtins.toJSON commands.systemctl}
    }
  '';
  quickshellConfig = pkgs.runCommandLocal "quickshell-config" {} ''
    cp -r ${./config} "$out"
    chmod -R u+w "$out"
    mkdir -p "$out/Shared"
    cp ${commandsFile} "$out/Shared/Commands.qml"
  '';
in {
  options.programs.quickshellBar = {
    enable = lib.mkEnableOption "Quickshell status bar";

    flashgenWordOfHour = {
      enable = (lib.mkEnableOption "Flashgen passive word-of-the-hour Quickshell widget") // {default = true;};

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

      tts = {
        enable = lib.mkEnableOption "Kokoro speech for the Flashgen word of the hour";

        endpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8880";
          description = "Kokoro-FastAPI base URL.";
        };

        chineseVoice = lib.mkOption {
          type = lib.types.str;
          default = "zf_xiaobei";
          description = "Kokoro voice for the Chinese sentence.";
        };

        englishVoice = lib.mkOption {
          type = lib.types.str;
          default = "af_heart";
          description = "Kokoro voice for the English translation.";
        };

        speed = lib.mkOption {
          type = lib.types.float;
          default = 0.9;
          description = "Kokoro playback speed multiplier.";
        };

        autoSpeak = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Speak the new word on the hourly notification unless dunst is paused.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = producerPackages;

    programs.quickshell = {
      enable = true;
      package = pkgs.quickshell;
      configs.bar = quickshellConfig;
      activeConfig = "bar";
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
    };
    xdg.configFile."quickshell/bar".force = true;

    # Stop with the session before its Wayland socket disappears.
    systemd.user.services.quickshell.Unit.PartOf = [config.programs.quickshell.systemd.target];
    systemd.user.services.quickshell-idle-inhibit = idleInhibit.service;
  };
}
