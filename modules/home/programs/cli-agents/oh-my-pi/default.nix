{
  config,
  lib,
  pkgs,
  flakes,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.oh-my-pi;

  sharedExtensions = import ../../../../../pkgs/pi-mono/extensions {inherit pkgs;};

  # The released `omp-linux-x64` binary bundles its own Bun runtime, so it does
  # not hit the nixpkgs Bun version check. Wrap it to optionally source an env
  # file (e.g. an agenix secret) before launching.
  ompPkg = pkgs.oh-my-pi;
  wrappedOmp = pkgs.symlinkJoin {
    name = "oh-my-pi-wrapped";
    paths = [ompPkg];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = optionalString (cfg.envFile != null) ''
      wrapProgram $out/bin/omp \
        --run '[ -f "${cfg.envFile}" ] && set -a && . "${cfg.envFile}" && set +a; true'
    '';
  };

  sharedSkillsFlat = import ../shared/skills.nix {inherit lib pkgs;};

  # skills.customDirectories is derived from config.home.homeDirectory, so it
  # is merged into the hand-written config instead of being duplicated there.
  derivedConfig = pkgs.writeText "omp-config-derived.yml" (builtins.toJSON {
    skills.customDirectories = ["${config.home.homeDirectory}/.omp/agent/skills"];
  });
  ompConfig = pkgs.runCommand "omp-config.yml" {nativeBuildInputs = [pkgs.yq-go];} ''
    yq -P eval-all 'select(fi == 0) * select(fi == 1)' ${./config.yml} ${derivedConfig} > $out
  '';
  # omp's task-agent frontmatter differs from Claude Code's: tool names are
  # lowercase, WebFetch doesn't exist (both WebFetch and WebSearch map to
  # web_search), model: "inherit" isn't valid (omit to inherit), and the
  # skills field is autoloadSkills. Transform the shared definitions so omp
  # can discover and dispatch them without breaking the other agents.
  ompSubAgents = pkgs.runCommand "omp-sub-agents" {} ''
    mkdir $out
    for f in ${../shared/sub-agents}/*.md; do
      sed \
        -e '/^tools:/s/Read/read/g' \
        -e '/^tools:/s/Grep/grep/g' \
        -e '/^tools:/s/Glob/glob/g' \
        -e '/^tools:/s/Bash/bash/g' \
        -e '/^tools:/s/Edit/edit/g' \
        -e '/^tools:/s/Write/write/g' \
        -e '/^tools:/s/WebFetch/web_search/g' \
        -e '/^tools:/s/WebSearch/web_search/g' \
        -e '/^tools:/s/\(web_search\), *web_search/\1/' \
        -e '/^model: inherit$/d' \
        -e 's/^skills:/autoloadSkills:/' \
        "$f" > "$out/$(basename "$f")"
    done
  '';
  compileExtension = args: pkgs.callPackage ../../../../../pkgs/pi-mono/extensions/compile-extension.nix args;
  plannotatorExt = compileExtension {src = ./extensions/plannotator-omp;};
  pluginFiles = import ./plugins.nix {inherit pkgs lib;};
in {
  options.programs.cli-agents.oh-my-pi = {
    enable = mkEnableOption "oh-my-pi (omp) CLI agent";
    envFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to an environment file sourced before launching omp (e.g. an agenix secret)";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [wrappedOmp];
    home.file =
      {
        ".omp/agent/skills" = {
          source = sharedSkillsFlat;
          recursive = true;
        };
        ".omp/agent/agents" = {
          source = ompSubAgents;
          recursive = true;
        };
        ".omp/agent/rules" = {
          source = ./rules;
          recursive = true;
        };
        ".omp/agent/AGENTS.md".source = ../shared/AGENTS.md;
        ".omp/agent/config.yml".source = ompConfig;
        ".omp/agent/extensions/docs-rs" = {
          source = sharedExtensions."docs-rs".src;
          recursive = true;
        };
        ".omp/agent/extensions/plannotator" = {
          source = plannotatorExt;
          recursive = true;
        };
        ".omp/agent/extensions/atuin.ts".source = ./extensions/atuin.ts;
        ".omp/agent/extensions/herdr-tab-title.ts".source = ./extensions/herdr-tab-title.ts;
        ".omp/agent/extensions/omp-nvim-bridge.ts".source = "${flakes.ompnvim}/extension/omp-nvim-bridge.ts";
        ".omp/agent/extensions/omp-helix-bridge.ts".source = ./extensions/omp-helix-bridge.ts;
      }
      // pluginFiles;
  };
}
