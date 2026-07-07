{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.oh-my-pi;

  # The released `omp-linux-x64` binary bundles its own Bun runtime, so it does
  # not hit the nixpkgs Bun version check. Wrap it to optionally source an env
  # file (e.g. an agenix secret) before launching.
  wrappedOmp = pkgs.symlinkJoin {
    name = "oh-my-pi-wrapped";
    paths = [pkgs.oh-my-pi];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = optionalString (cfg.envFile != null) ''
      wrapProgram $out/bin/omp \
        --run '[ -f "${cfg.envFile}" ] && set -a && . "${cfg.envFile}" && set +a; true'
    '';
  };

  # omp's skill scanners (provider-based and `skills.customDirectories`) are
  # one-level non-recursive: only `<root>/<name>/SKILL.md` is discovered. The
  # skills shared with Claude/Codex/Amp live nested one level deeper, at
  # `~/.claude/skills/<group>/<name>/SKILL.md` (e.g. `workflows/caveman`), so
  # they're invisible to omp unless each group directory is registered as its
  # own scan root. Derive the group list from the shared skills tree so it
  # never drifts from what's actually on disk.
  sharedSkillGroups = attrNames (filterAttrs (name: type: type == "directory" && !pathExists (../shared/skills + "/${name}/SKILL.md")) (builtins.readDir ../shared/skills));
  sharedSkillDirectories = map (group: "${config.home.homeDirectory}/.claude/skills/${group}") sharedSkillGroups;
in {
  options.programs.cli-agents.oh-my-pi = {
    enable = mkEnableOption "oh-my-pi (omp) CLI agent";
    envFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path to an environment file sourced before launching omp (e.g. an agenix secret)";
    };
    disabledProviders = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["claude"];
      description = ''
        Authoritative value for omp's `disabledProviders` setting. Covers both
        discovery sources (`claude`, `codex`, `gemini`, `native`, ...) and model
        backends (`anthropic`, `openai`, ...). Per the module doc this is meant
        to also cut off Claude-supplied skills, but that's unverified/possibly
        stale: on a host with `disabledProviders = ["claude"]` set, flat
        `~/.claude/skills/<name>/SKILL.md` skills still loaded in practice
        (confirmed by content, not just presence). Treat the skills claim in
        this setting's effect with suspicion until re-verified against a
        current omp build.

        omp stores this in its mutable `~/.omp/agent/config.yml`, so it cannot be
        a read-only symlink. We persist it via `omp config set` on activation
        instead. Because the setting is a wholesale array, this list replaces any
        `disabledProviders` set at runtime (e.g. via `/settings`) on each rebuild.
      '';
    };
    theme = {
      dark = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "dark-aurora";
        description = ''
          Theme used when omp detects a dark terminal background. If unset,
          omp keeps its existing mutable config value.
        '';
      };
      light = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "light";
        description = ''
          Theme used when omp detects a light terminal background. If unset,
          omp keeps its existing mutable config value.
        '';
      };
    };

    discoverNestedSkills = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Register every subdirectory of the shared skills tree
        (`modules/home/programs/cli-agents/shared/skills/<group>/`) as its own
        `skills.customDirectories` scan root in omp.

        omp's skill discovery only finds `<root>/<name>/SKILL.md` (one level,
        non-recursive). Skills shared with Claude/Codex/Amp live at
        `~/.claude/skills/<group>/<name>/SKILL.md` (e.g. `workflows/caveman`),
        so without this every nested skill is silently invisible to omp even
        though flat ones (`~/.claude/skills/<name>/SKILL.md`) load fine.

        Requires `programs.cli-agents.claude.enable` (the source of
        `~/.claude/skills`); this is asserted at eval time.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.discoverNestedSkills || config.programs.cli-agents.claude.enable;
        message = "programs.cli-agents.oh-my-pi.discoverNestedSkills requires programs.cli-agents.claude.enable (the source of ~/.claude/skills)";
      }
    ];

    home.packages = [wrappedOmp];
    home.file.".omp/agent/extensions/caveman" = {
      source = ./extensions/caveman;
      recursive = true;
    };

    home.activation.ohMyPiDisabledProviders = mkIf (cfg.disabledProviders != []) (
      hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
        $DRY_RUN_CMD ${pkgs.oh-my-pi}/bin/omp config set disabledProviders '${builtins.toJSON cfg.disabledProviders}'
      ''
    );

    home.activation.ohMyPiTheme = mkIf (cfg.theme.dark != null || cfg.theme.light != null) (
      hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
        ${optionalString (cfg.theme.dark != null) ''
          $DRY_RUN_CMD ${pkgs.oh-my-pi}/bin/omp config set theme.dark ${escapeShellArg cfg.theme.dark}
        ''}${optionalString (cfg.theme.light != null) ''
          $DRY_RUN_CMD ${pkgs.oh-my-pi}/bin/omp config set theme.light ${escapeShellArg cfg.theme.light}
        ''}
      ''
    );

    home.activation.ohMyPiSkillDirectories = mkIf cfg.discoverNestedSkills (
      hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
        $DRY_RUN_CMD ${pkgs.oh-my-pi}/bin/omp config set skills.customDirectories '${builtins.toJSON sharedSkillDirectories}'
      ''
    );
  };
}
