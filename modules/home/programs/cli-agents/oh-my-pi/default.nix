{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.oh-my-pi;

  extensions = import ../../../../../pkgs/pi-mono/extensions {inherit pkgs;};

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

  sharedSkills = ../shared/skills;
  sharedSkillDirectories = map (group: "${config.home.homeDirectory}/.omp/agent/skills/${group}") (
    attrNames (filterAttrs (_: type: type == "directory") (builtins.readDir sharedSkills))
  );
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
  flattenSettings = prefix: value:
    if isAttrs value
    then concatLists (mapAttrsToList (name: nested: flattenSettings "${prefix}${name}." nested) value)
    else [
      {
        path = removeSuffix "." prefix;
        inherit value;
      }
    ];
  defaultSettings = {
    theme = {
      dark = "graphite";
      light = "light";
    };
    modelRoles = {
      default = "openai-codex/gpt-5.6-luna:xhigh";
      advisor = "openai-codex/gpt-5.6-sol:low";
      slow = "openai-codex/gpt-5.6-sol:high";
      smol = "openai-codex/gpt-5.6-luna:high";
    };
    symbolPreset = "unicode";
    setupVersion = 1;
    dev = {
      autoqaConsent = "denied";
      autoqa = false;
    };
    autolearn = {
      enabled = true;
      autoContinue = true;
    };
    memory.backend = "mnemopi";
    mnemopi = {
      enhancedRecall = true;
      polyphonicRecall = true;
      proactiveLinking = true;
      scoping = "per-project-tagged";
    };
    github.enabled = true;
    bash.autoBackground.enabled = true;
    codexResets.autoRedeem = "no";
    steeringMode = "all";
    advisor.enabled = true;
    task = {
      showResolvedModelBadge = true;
      eager = "always";
      prewalk = true;
      enableEffort = true;
    };
    compaction.handoffSaveToDisk = true;
    hideThinkingBlock = false;
    externalThinking = true;
    personality = "pragmatic";
    providers.unexpectedStopModel = "online";
    features.unexpectedStopDetection = true;
    display = {
      showTokenUsage = true;
      cacheMissMarker = true;
    };
    prewalk = {
      enabled = false;
    };
  };
  effectiveSettings =
    recursiveUpdate (recursiveUpdate defaultSettings {
      skills.customDirectories = sharedSkillDirectories;
    })
    cfg.settings;
  settingCommands = concatStringsSep "\n" (map (
    setting: "$DRY_RUN_CMD ${ompPkg}/bin/omp config set ${escapeShellArg setting.path} ${escapeShellArg (builtins.toJSON setting.value)}"
  ) (flattenSettings "" effectiveSettings));
  compileExtension = args: pkgs.callPackage ../../../../../pkgs/pi-mono/extensions/compile-extension.nix args;
  plannotatorExt = compileExtension {src = ./plannotator-omp;};
in {
  options.programs.cli-agents.oh-my-pi = {
    enable = mkEnableOption "oh-my-pi (omp) CLI agent";
    envFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to an environment file sourced before launching omp (e.g. an agenix secret)";
    };
    settings = mkOption {
      type = types.attrs;
      default = defaultSettings;
      apply = value: recursiveUpdate defaultSettings value;
      description = "OMP settings applied on activation; omitted settings use module defaults.";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [wrappedOmp];
    home.file.".omp/agent/skills" = {
      source = sharedSkills;
      recursive = true;
    };
    home.file.".omp/agent/agents" = {
      source = ompSubAgents;
      recursive = true;
    };
    home.file.".omp/agent/AGENTS.md".source = ../shared/AGENTS.md;
    home.file.".omp/agent/extensions/docs-rs" = {
      source = extensions."docs-rs".src;
      recursive = true;
    };
    home.file.".omp/agent/extensions/plannotator" = {
      source = plannotatorExt;
      recursive = true;
    };
    home.file.".omp/agent/extensions/atuin.ts".source = ./atuin.ts;
    home.file.".omp/agent/extensions/herdr-tab-title.ts".source = ./herdr-tab-title.ts;

    home.activation.ohMyPiSettings = hm.dag.entryAfter ["writeBoundary"] ''
      ${optionalString (cfg.settings != {}) ''
        $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
      ''}
      ${settingCommands}
    '';
  };
}
