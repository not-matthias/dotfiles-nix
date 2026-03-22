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
    mkEntry = type: subdir: {
      ".pi/agent/${type}/${name}" = {
        source =
          if isAbsolute type
          then subdir
          else "${ext.src}/${subdir}";
        recursive = false;
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
  settings =
    settingsBase
    // {
      packages = map (name: "./packages/${name}") (builtins.attrNames packages);
    };
  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON settings);
in {
  options.programs.cli-agents.pi-mono = {
    enable = mkEnableOption "Pi-Mono CLI agent";
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.pi-coding-agent pkgs.pi-session-cli];

    # Exclude per-project Pi state/config from git by default
    programs.git.ignores = mkAfter [".pi"];

    # Pi uses ~/.pi/agent/ as its config directory
    home.file =
      {
        ".pi/agent/AGENTS.md" = {
          source = ../shared/AGENTS.md;
        };
        ".pi/APPEND_SYSTEM.md" = {
          source = ./APPEND_SYSTEM.md;
        };
        ".pi/agent/settings.json" = {
          source = settingsFile;
        };
        ".pi/agent/themes/stylix-latte-red.json" = {
          source = ./themes/stylix-latte-red.json;
        };
        ".pi/agent/prompts/shared" = {
          source = ../shared/commands;
          recursive = false;
        };
        ".pi/agent/skills/shared" = {
          source = ../shared/skills;
          recursive = false;
        };
        ".pi/agent/agents/shared" = {
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
      }
      // extensionFiles
      // packageFiles;
  };
}
