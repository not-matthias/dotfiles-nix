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
    version = "0.9.0";
    assets = {
      x86_64-linux = {
        name = "herdr-linux-x86_64";
        hash = "sha256-T6GgEVjdgEPaktMbJweAsNzBBgMDjZthysTYGrY/tx8=";
      };
      aarch64-linux = {
        name = "herdr-linux-aarch64";
        hash = "sha256-nI2yD7fnQnsTjVNnET8WIf/TGfL2XW8AniWUApEV8NI=";
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
  renameAgent = pkgs.writeShellScript "herdr-rename-agent" ''
    set -eu
    herdr="''${HERDR_BIN_PATH:?HERDR_BIN_PATH is not set}"
    pane_id="''${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID is not set}"
    printf "Agent name: "
    IFS= read -r name
    test -n "$name" || exit 0
    exec "$herdr" agent rename "$pane_id" "$name"
  '';
  # Activation hooks may run before the home profile exposes newly declared packages.
  # Keep the toolchains plugin build steps need available explicitly.
  githubActivationPath = lib.makeBinPath [
    pkgs.bash
    pkgs.bun
    pkgs.git
    pkgs.go
  ];

  linkPlugin = plugin: let
    enabledFlag = optionalString (!plugin.enable) " --disabled";
  in ''
    $DRY_RUN_CMD ${lib.getExe package} plugin link ${lib.escapeShellArg (toString plugin.path)}${enabledFlag}
  '';

  installGithubPlugin = plugin: ''
    if ! "$herdr" plugin list --json | ${pkgs.jq}/bin/jq -e \
      '.result.plugins[]? | select(.source.resolved_commit == ${builtins.toJSON plugin.rev})' \
      >/dev/null; then
      # The installer clones over the network, which is unreachable while
      # switch-to-configuration restarts NetworkManager/resolved. Retry next switch.
      $DRY_RUN_CMD "$herdr" plugin install ${lib.escapeShellArg plugin.source} --ref ${lib.escapeShellArg plugin.rev} --yes \
        || warnEcho "herdr: ${plugin.source} plugin install failed, leaving current version in place"
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

    github = mkOption {
      type = types.listOf (types.submodule {
        options = {
          source = mkOption {
            type = types.str;
            example = "owner/repo";
            description = "GitHub `owner/repo[/subdir]` passed to `herdr plugin install`.";
          };

          rev = mkOption {
            type = types.strMatching "[0-9a-f]{40}";
            description = "Full commit hash to install; compared against Herdr's recorded resolved commit.";
          };
        };
      });
      default = [];
      description = "Plugins Herdr installs from GitHub and builds locally when the pinned commit is not installed.";
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
        command = [
          {
            key = "prefix+shift+r";
            type = "popup";
            command = "${renameAgent}";
            width = "60%";
            height = "20%";
          }
        ];
      };
      ui = {
        agent_panel_sort = "priority";
        sidebar_width = 50;
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

    home.activation.herdrGithubPlugins = mkIf (cfg.github != []) (
      hm.dag.entryAfter ["writeBoundary"] ''
        export PATH="${githubActivationPath}:$PATH"
        herdr="${lib.getExe package}"
        ${concatMapStrings installGithubPlugin cfg.github}
      ''
    );
  };
}
