{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.herdr;
  tomlFormat = pkgs.formats.toml {};
  configFile = tomlFormat.generate "herdr-config.toml" cfg.settings;
  herdr = let
    version = "0.7.5";
    assets = {
      x86_64-linux = {
        name = "herdr-linux-x86_64";
        hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
      };
      aarch64-linux = {
        name = "herdr-linux-aarch64";
        hash = "sha256-MudjoUmaa2lLHXCOTwYrdDvh2p80/PpNIS1ttv4JqLk=";
      };
    };
    asset =
      assets.${pkgs.stdenv.hostPlatform.system}
      or (throw "Herdr ${version} is not available for ${pkgs.stdenv.hostPlatform.system}");
  in
    pkgs.stdenvNoCC.mkDerivation {
      pname = "herdr";
      inherit version;

      src = pkgs.fetchurl {
        url = "https://github.com/ogulcancelik/herdr/releases/download/v${version}/${asset.name}";
        inherit (asset) hash;
      };

      dontUnpack = true;

      installPhase = ''
        install -Dm755 $src $out/bin/herdr
      '';

      meta = {
        description = "Terminal agent multiplexer";
        homepage = "https://github.com/ogulcancelik/herdr";
        license = licenses.agpl3Plus;
        mainProgram = "herdr";
        platforms = attrNames assets;
      };
    };
  package = cfg.package;
  linkPlugin = plugin: let
    enabledFlag = optionalString (!plugin.enable) " --disabled";
    herdrSock = "${config.xdg.configHome}/herdr/herdr.sock";
  in ''
    # herdr plugin link is an IPC call to the running daemon; skip when no session is active.
    if [ -S "${herdrSock}" ]; then
      $DRY_RUN_CMD ${lib.getExe package} plugin link ${lib.escapeShellArg (toString plugin.path)}${enabledFlag}
    fi
  '';
in {
  options.programs.cli-agents.herdr = {
    enable = mkEnableOption "Herdr terminal agent multiplexer";

    package = mkOption {
      type = types.package;
      default = herdr;
      defaultText = literalExpression "herdr";
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

    programs.cli-agents.herdr.settings = mkDefault {
      onboarding = false;
      update = {
        version_check = false;
        manifest_check = false;
      };
      theme.name = "terminal";
      keys = {
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
      ui = {
        agent_panel_sort = "priority";
        sidebar_width = 36;
        show_agent_labels_on_pane_borders = true;
        hide_tab_bar_when_single_tab = true;
        toast.delivery = "herdr";
        sidebar = {
          spaces.row_gap = 1;
          agents.row_gap = 1;
        };
      };
    };

    xdg.configFile."herdr/config.toml" = mkIf (cfg.settings != {}) {
      source = configFile;
    };

    home.activation.herdrPlugins = mkIf (cfg.plugins != []) (
      hm.dag.entryAfter ["writeBoundary"] (concatMapStrings linkPlugin cfg.plugins)
    );
  };
}
