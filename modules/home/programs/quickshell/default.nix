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
  battery = import ./config/Components/Battery/default.nix {inherit pkgs;};

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
      battery
    ]
    ++ lib.optionals flashgenEnabled [flashgen.script]
    ++ lib.optionals (!flashgenEnabled) [flashgenFallback];

  commands = {
    flashgen = flashgenCommand;
    claudeUsage = "${aiUsage.claudeScript}/bin/quickshell-claude-usage";
    codexUsage = "${aiUsage.codexScript}/bin/quickshell-codex-usage";
    antigravityUsage = "${aiUsage.antigravityScript}/bin/quickshell-antigravity-usage";
    statusBridge = "${statusBridge.bridge}/bin/quickshell-status-bridge";
    batteryStatus = "${battery}/bin/quickshell-battery-status";
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
        readonly property string batteryStatus: ${builtins.toJSON commands.batteryStatus}
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

    systemd.user.services.quickshell-idle-inhibit = idleInhibit.service;
  };
}
