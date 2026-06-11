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
  };

  # omp shares the ~/.pi/agent config directory managed by the pi-mono module.
  config = mkIf cfg.enable {
    home.packages = [wrappedOmp];
  };
}
