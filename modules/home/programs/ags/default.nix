{
  config,
  flakes,
  lib,
  pkgs,
  ...
}: let
  agsPackages = flakes.ags.packages.${pkgs.stdenv.hostPlatform.system};
  cfg = config.programs.ags;
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
    then "${flashgenWord.script}/bin/flashgen-word-of-hour"
    else "${pkgs.jq}/bin/jq -nc '{text:\"\",tooltip:\"\"}'";

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
      cfg.package
      pkgs.gawk
      pkgs.jq
      pkgs.niri
      pkgs.pavucontrol
      pkgs.systemd
      pkgs.wireplumber
    ]
    ++ producerPackages;
  runtimePath = lib.makeBinPath runtimePackages;

  commandsConfig = {
    niriState = "${niriState}/bin/ags-niri-state";
    flashgen = flashgenCommand;
    claudeUsage = "${aiUsage.claudeScript}/bin/ags-claude-usage";
    codexUsage = "${aiUsage.codexScript}/bin/ags-codex-usage";
    antigravityUsage = "${aiUsage.antigravityScript}/bin/ags-antigravity-usage";
    idleInhibitStatus = "${idleInhibit.status}/bin/ags-idle-inhibit-status";
    dndStatus = "${dnd}/bin/ags-dnd-status";
    volumeStatus = "${volume}/bin/ags-volume-status";
    batteryStatus = "${battery}/bin/ags-battery-status";
    pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
    dunstctl = "${pkgs.dunst}/bin/dunstctl";
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    niri = "${pkgs.niri}/bin/niri";
    systemctl = "${pkgs.systemd}/bin/systemctl";
  };
in {
  options.programs.ags = {
    enable = lib.mkEnableOption "AGS status bar";

    package = lib.mkOption {
      type = lib.types.package;
      default = agsPackages.ags.override {
        extraPackages = [agsPackages.tray];
      };
      description = "AGS package with Astal extensions.";
    };
    systemd.enable = lib.mkEnableOption "AGS systemd service";

    flashgenWordOfHour = {
      enable = (lib.mkEnableOption "Flashgen passive word-of-the-hour AGS widget") // {default = true;};

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
    home.packages = [cfg.package pkgs.pavucontrol] ++ producerPackages;

    xdg.configFile = {
      "ags" = {
        source = ./config;
        recursive = true;
      };
      "ags/commands.ts".text = "export default ${builtins.toJSON commandsConfig} as const\n";
    };

    systemd.user.services =
      {
        ags-idle-inhibit = idleInhibit.service;
      }
      // lib.optionalAttrs cfg.systemd.enable {
        ags = {
          Unit = {
            Description = "AGS status bar";
            PartOf = ["graphical-session.target"];
            After = ["graphical-session.target"];
          };
          Service = {
            Environment = "PATH=${runtimePath}";
            ExecStart = "${cfg.package}/bin/ags run ${config.xdg.configHome}/ags/app.tsx";
            Restart = "on-failure";
            RestartSec = 1;
          };
          Install.WantedBy = ["graphical-session.target"];
        };
      };
  };
}
