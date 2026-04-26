{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.pi-mono;

  extensions = import ../../../../../pkgs/pi-mono/extensions {inherit pkgs;};
  packages = import ../../../../../pkgs/pi-mono/packages {inherit pkgs;};

  # Generate home.file entries for a single extension's resources.
  # Each resource type (extensions, skills, themes, prompts) gets symlinked
  # into the appropriate ~/.pi/agent/<type>/<name> directory.
  mkExtensionFiles = name: ext: let
    resources = ext.resources or {};
    isAbsolute = type:
      (type == "extensions" && (ext.extensionsAbsolute or false))
      || (type == "skills" && (ext.skillsAbsolute or false));
    isRecursive = type:
      (type == "extensions" && (ext.extensionsRecursive or false))
      || (type == "skills" && (ext.skillsRecursive or false));
    mkEntry = type: subdir: {
      ".pi/agent/${type}/${name}" = {
        source =
          if isAbsolute type
          then subdir
          else "${ext.src}/${subdir}";
        recursive = isRecursive type;
      };
    };
  in
    (optionalAttrs (resources ? extensions) (mkEntry "extensions" resources.extensions))
    // (optionalAttrs (resources ? skills) (mkEntry "skills" resources.skills))
    // (optionalAttrs (resources ? themes) (mkEntry "themes" resources.themes))
    // (optionalAttrs (resources ? prompts) (mkEntry "prompts" resources.prompts));

  # Merge all extension file entries
  extensionFiles = foldlAttrs (acc: name: ext: acc // mkExtensionFiles name ext) {} extensions;

  # Symlink npm packages into ~/.pi/agent/packages/<name> so settings.json
  # can reference them as local paths instead of runtime npm: installs
  packageFiles = mapAttrs' (name: src:
    nameValuePair ".pi/agent/packages/${name}" {
      source = src;
    })
  packages;

  # Generate settings.json with local package paths instead of npm: prefixes
  settingsBase = builtins.fromJSON (builtins.readFile ./settings.json);
  keybindings = settingsBase.keybindings or {};
  settings =
    settingsBase
    // {
      packages = map (name: "./packages/${name}") (builtins.attrNames packages);
    };
  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON settings);
  keybindingsFile = pkgs.writeText "pi-keybindings.json" (builtins.toJSON keybindings);

  wrappedPi = pkgs.symlinkJoin {
    name = "pi-coding-agent-wrapped";
    paths = [pkgs.pi-coding-agent];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/pi \
        --run '${optionalString (cfg.envFile != null) ''[ -f "${cfg.envFile}" ] && set -a && . "${cfg.envFile}" && set +a; ''}if [ -z "''${CLAUDE_CODE_EXECUTABLE:-}" ] && command -v claude >/dev/null 2>&1; then export CLAUDE_CODE_EXECUTABLE="$(command -v claude)"; fi'
    '';
  };
in {
  options.programs.cli-agents.pi-mono = {
    enable = mkEnableOption "Pi-Mono CLI agent";
    envFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to an environment file sourced before launching pi (e.g. an agenix secret)";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [wrappedPi pkgs.pi-session-cli];

    # Exclude per-project Pi state/config from git by default
    programs.git.ignores = mkAfter [".pi"];

    # Pi uses ~/.pi/agent/ as its config directory
    home.file =
      {
        ".pi/agent/AGENTS.md" = {
          source = ../shared/AGENTS.md;
        };
        ".pi/agent/APPEND_SYSTEM.md" = {
          source = ./APPEND_SYSTEM.md;
        };
        ".pi/agent/settings.json" = {
          source = settingsFile;
        };
        ".pi/agent/keybindings.json" = {
          source = keybindingsFile;
        };
        ".pi/agent/claude-bridge.json" = {
          source = ./claude-bridge.json;
        };
        ".pi/agent/verbosity.json" = {
          source = ./verbosity.json;
        };
        ".pi/agent/models.json" = {
          source = ./models.json;
        };
        ".pi/agent/themes/stylix-latte-red.json" = {
          source = ./themes/stylix-latte-red.json;
        };
        ".pi/agent/themes/stylix-mocha-red.json" = {
          source = ./themes/stylix-mocha-red.json;
        };
        ".pi/agent/skills/shared" = {
          source = ../shared/skills;
          recursive = false;
        };
        ".pi/agent/agents" = {
          source = ../shared/sub-agents;
          recursive = false;
        };
        # Extension config files
        ".pi/agent/extensions/guardrails.json" = {
          source = ./extensions/guardrails.json;
        };
        ".pi/agent/extensions/toolchain.json" = {
          source = ./extensions/toolchain.json;
        };
        ".pi/agent/extensions/pi-tool-display/config.json" = {
          text = builtins.toJSON {
            readOutputMode = "summary";
            searchOutputMode = "count";
            bashOutputMode = "opencode";
            diffViewMode = "auto";
          };
        };
      }
      // extensionFiles
      // packageFiles;
  };
}
