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
    version = "0.8.0";
    assets = {
      x86_64-linux = {
        name = "herdr-linux-x86_64";
        hash = "sha256-uHLqfkD6LLF+hXrJtisb8m23tAPGIvXS8/WzX26azSg=";
      };
      aarch64-linux = {
        name = "herdr-linux-aarch64";
        hash = "sha256-9kesZkaNnvvGQv5TT7KERo8K6mBkFgb8AI38DYKjyoc=";
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
        url = "https://github.com/herdrdev/herdr/releases/download/v${version}/${asset.name}";
        inherit (asset) hash;
      };

      dontUnpack = true;

      installPhase = ''
        install -Dm755 $src $out/bin/herdr
      '';

      meta = {
        description = "Terminal agent multiplexer";
        homepage = "https://github.com/herdrdev/herdr";
        license = licenses.asl20;
        mainProgram = "herdr";
        platforms = attrNames assets;
      };
    };
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
        previous_tab = ["prefix+p" "ctrl+alt+[" "ctrl+shift+tab"];
        next_tab = ["prefix+n" "ctrl+alt+]" "ctrl+tab"];
        new_tab = ["prefix+c" "ctrl+alt+c"];
        split_vertical = ["prefix+v" "ctrl+alt+d"];
        split_horizontal = ["prefix+minus" "ctrl+alt+shift+d"];
        zoom = ["prefix+z" "ctrl+alt+z"];
        last_pane = "ctrl+alt+tab";
        next_agent = "prefix+.";
        previous_agent = "prefix+,";
        focus_agent = "prefix+shift+1..9";
        toggle_sidebar = ["prefix+b" "ctrl+alt+b"];
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

    # herdr writes config.toml at runtime; keep it a mutable regular file,
    # seeding from the declarative config only when missing or still a Nix symlink.
    home.activation.herdrConfig = mkIf (cfg.settings != {}) (
      hm.dag.entryAfter ["writeBoundary"] ''
        target="$HOME/.config/herdr/config.toml"
        if [[ ! -e "$target" || -L "$target" ]]; then
          $DRY_RUN_CMD rm -f "$target"
          $DRY_RUN_CMD install -Dm644 ${configFile} "$target"
        fi
      ''
    );

    home.activation.herdrPlugins = mkIf (cfg.plugins != []) (
      hm.dag.entryAfter ["writeBoundary"] (concatMapStrings linkPlugin cfg.plugins)
    );
  };
}
