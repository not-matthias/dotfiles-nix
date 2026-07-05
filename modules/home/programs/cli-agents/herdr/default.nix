{
  config,
  hm,
  lib,
  pkgs,
  unstable,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.herdr;
  tomlFormat = pkgs.formats.toml {};
  configFile = tomlFormat.generate "herdr-config.toml" cfg.settings;
  package = cfg.package;
  linkPlugin = plugin: let
    enabledFlag = optionalString (!plugin.enable) " --disabled";
  in ''
    $DRY_RUN_CMD ${lib.getExe package} plugin link ${lib.escapeShellArg (toString plugin.path)}${enabledFlag}
  '';
in {
  options.programs.cli-agents.herdr = {
    enable = mkEnableOption "Herdr terminal agent multiplexer";

    package = mkOption {
      type = types.package;
      default = unstable.herdr;
      defaultText = literalExpression "unstable.herdr";
      description = "Herdr package to install and use for plugin activation.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = {};
      example = literalExpression ''
        {
          onboarding = false;
          theme.name = "terminal";
          ui.show_agent_labels_on_pane_borders = true;
        }
      '';
      description = "Herdr configuration written to ~/.config/herdr/config.toml.";
    };

    plugins = mkOption {
      type = types.listOf (types.submodule {
        options = {
          path = mkOption {
            type = types.oneOf [types.path types.package types.str];
            description = "Local plugin directory containing herdr-plugin.toml.";
          };

          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether Herdr should link the plugin as enabled.";
          };
        };
      });
      default = [];
      example = literalExpression ''
        [
          {
            path = pkgs.fetchFromGitHub {
              owner = "owner";
              repo = "herdr-plugin";
              rev = "commit";
              hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            };
          }
        ]
      '';
      description = "Plugin source directories to link idempotently with `herdr plugin link`.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [package];

    programs.cli-agents.herdr.settings.keys = mkDefault {
      prefix = "ctrl+b";
      focus_pane_left = ["prefix+h" "ctrl+alt+h"];
      focus_pane_down = ["prefix+j" "ctrl+alt+j"];
      focus_pane_up = ["prefix+k" "ctrl+alt+k"];
      focus_pane_right = ["prefix+l" "ctrl+alt+l"];
      previous_tab = ["prefix+p" "ctrl+alt+["];
      next_tab = ["prefix+n" "ctrl+alt+]"];
      new_tab = ["prefix+c" "ctrl+alt+c"];
      split_vertical = ["prefix+v" "ctrl+alt+d"];
      split_horizontal = ["prefix+minus" "ctrl+alt+shift+d"];
      zoom = ["prefix+z" "ctrl+alt+z"];
      switch_workspace = "prefix+shift+1..9";
      last_pane = "ctrl+alt+tab";
    };

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = configFile;
    };

    home.activation.herdrPlugins = mkIf (cfg.plugins != []) (
      hm.dag.entryAfter ["writeBoundary"] (concatMapStrings linkPlugin cfg.plugins)
    );
  };
}
