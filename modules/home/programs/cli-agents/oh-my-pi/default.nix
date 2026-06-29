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
        backends (`anthropic`, `openai`, ...). Disabling the `claude` discovery
        source stops omp from loading CLAUDE.md plus any Claude-supplied MCP
        servers, commands, skills, hooks, and settings.

        omp stores this in its mutable `~/.omp/agent/config.yml`, so it cannot be
        a read-only symlink. We persist it via `omp config set` on activation
        instead. Because the setting is a wholesale array, this list replaces any
        `disabledProviders` set at runtime (e.g. via `/settings`) on each rebuild.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [wrappedOmp];

    home.activation.ohMyPiDisabledProviders = mkIf (cfg.disabledProviders != []) (
      hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
        $DRY_RUN_CMD ${pkgs.oh-my-pi}/bin/omp config set disabledProviders '${builtins.toJSON cfg.disabledProviders}'
      ''
    );
  };
}
