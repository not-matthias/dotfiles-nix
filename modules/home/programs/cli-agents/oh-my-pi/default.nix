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
  # OMP customDirectories must point at directories whose immediate children
  # are skill directories. Recurse to find every such parent (e.g. "coding",
  # "third-party/mattpocock") at arbitrary depth.
  findSkillParents = rel: dir: let
    subdirs = attrNames (filterAttrs (_: type: type == "directory") (builtins.readDir dir));
    isSkill = name: builtins.pathExists (dir + "/${name}/SKILL.md");
  in
    optional (any isSkill subdirs) rel
    ++ concatMap (
      name:
        if isSkill name
        then []
        else findSkillParents "${rel}${optionalString (rel != "") "/"}${name}" (dir + "/${name}")
    )
    subdirs;
  sharedSkillDirectories =
    map (rel: "${config.home.homeDirectory}/.omp/agent/skills/${rel}")
    (findSkillParents "" sharedSkills);
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
  recordKeys = [
    "modelRoles"
    "modelTags"
    "tools.approval"
    "statusLine.segmentOptions"
    "retry.fallbackChains"
    "task.agentModelOverrides"
    "task.agentPrewalk"
    "task.agentAdvisor"
    "providers.maxInFlightRequests"
  ];
  flattenSettings = prefix: value: let
    path = removeSuffix "." prefix;
  in
    if isAttrs value && !(elem path recordKeys)
    then concatLists (mapAttrsToList (name: nested: flattenSettings "${prefix}${name}." nested) value)
    else [
      {
        inherit path value;
      }
    ];
  defaultSettings = {
    theme = {
      dark = "graphite";
      light = "light";
    };
    modelRoles = {
      default = "google-antigravity/gemini-3.7-flash";
      # FIXME: switch back to gemini-3.7-flash once title generation / disableReasoning works (Antigravity sends thinkingLevel: MINIMAL which 400s)
      tiny = "anthropic/claude-haiku-4-5";
      commit = "google-antigravity/gemini-3.7-flash";
      task = "google-antigravity/gemini-3.7-flash";
      advisor = "openai-codex/gpt-5.6-sol:medium";
      slow = "openai-codex/gpt-5.6-sol:xhigh";
      plan = "openai-codex/gpt-5.6-sol:high";
      smol = "google-antigravity/gemini-3.7-flash";
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
      agentModelOverrides = {
        scout = "google-antigravity/gemini-3.7-flash";
        librarian = "google-antigravity/gemini-3.7-flash";
        oracle = "openai-codex/gpt-5.6-sol:xhigh";
        solver = "openai-codex/gpt-5.6-sol:xhigh";
        reviewer = "openai-codex/gpt-5.6-sol:high";
        security-reviewer = "openai-codex/gpt-5.6-sol:high";
      };
    };
    compaction.handoffSaveToDisk = true;
    hideThinkingBlock = false;
    externalThinking = true;
    personality = "pragmatic";
    providers = {
      tinyModel = "online";
      memoryModel = "online";
      unexpectedStopModel = "online";
      imageOrder = [
        "google-antigravity"
        "openai-codex"
        "anthropic"
      ];
    };
    inspect_image = {
      enabled = true;
      mode = "auto";
    };
    features.unexpectedStopDetection = true;
    display = {
      showTokenUsage = true;
      cacheMissMarker = true;
    };
    prewalk = {
      enabled = false;
    };
    retry = {
      modelFallback = true;
      usageAwareFallback = true;
      fallbackChains = {
        "google-antigravity/gemini-3.7-flash" = [
          "openai-codex/gpt-5.6-luna"
          "anthropic/claude-sonnet-5"
        ];
        "openai-codex/gpt-5.6-sol" = [
          "anthropic/claude-fable-5"
          "google-antigravity/gemini-3.7-flash"
        ];
        "anthropic/claude-fable-5" = [
          "openai-codex/gpt-5.6-sol"
          "google-antigravity/gemini-3.7-flash"
        ];
      };
    };
  };
  effectiveSettings =
    recursiveUpdate (recursiveUpdate defaultSettings {
      skills.customDirectories = sharedSkillDirectories;
    })
    cfg.settings;
  formatValue = value:
    if isString value
    then value
    else builtins.toJSON value;
  settingCommands = concatStringsSep "\n" (map (
    setting: "$DRY_RUN_CMD ${ompPkg}/bin/omp config set ${escapeShellArg setting.path} ${escapeShellArg (formatValue setting.value)}"
  ) (flattenSettings "" effectiveSettings));
  compileExtension = args: pkgs.callPackage ../../../../../pkgs/pi-mono/extensions/compile-extension.nix args;
  plannotatorExt = compileExtension {src = ./plannotator-omp;};
  plugins = import ./plugins.nix {inherit pkgs;};
  pluginFiles =
    foldlAttrs (
      acc: name: p:
        acc
        // {
          ".local/share/omp/plugins/node_modules/${name}".source = p.source;
        }
    ) {
      ".local/share/omp/plugins/package.json".text = builtins.toJSON {
        name = "omp-plugins";
        private = true;
        dependencies = mapAttrs (name: _: "npm:${name}") plugins;
      };
      ".local/share/omp/plugins/omp-plugins.lock.json".text = builtins.toJSON {
        plugins =
          mapAttrs (_: p: {
            version = p.version;
            enabledFeatures = null;
            enabled = true;
          })
          plugins;
        settings = {};
      };
    }
    plugins;
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
    home.file =
      {
        ".omp/agent/skills" = {
          source = sharedSkills;
          recursive = true;
        };
        ".omp/agent/agents" = {
          source = ompSubAgents;
          recursive = true;
        };
        ".omp/agent/AGENTS.md".source = ../shared/AGENTS.md;
        ".omp/agent/extensions/docs-rs" = {
          source = extensions."docs-rs".src;
          recursive = true;
        };
        ".omp/agent/extensions/plannotator" = {
          source = plannotatorExt;
          recursive = true;
        };
        ".omp/agent/extensions/atuin.ts".source = ./atuin.ts;
        ".omp/agent/extensions/herdr-tab-title.ts".source = ./herdr-tab-title.ts;
      }
      // pluginFiles;

    home.activation.ohMyPiSettings = hm.dag.entryAfter ["writeBoundary"] ''
      ${optionalString (cfg.settings != {}) ''
        $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
      ''}
      ${settingCommands}
    '';
  };
}
