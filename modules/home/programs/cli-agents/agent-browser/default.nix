{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.cli-agents.agent-browser;
  version = "0.22.3";
  cacheDir = "/tmp/agent-browser-npm-cache-${version}";
  prefixDir = "/tmp/agent-browser-npm-prefix-${version}";
  package = pkgs.writeShellScriptBin "agent-browser" ''
    set -euo pipefail

    # Clear cache if corrupted (missing package.json means broken extraction)
    if [ -d "${cacheDir}/_npx" ] && ! find "${cacheDir}/_npx" -name "package.json" -path "*/agent-browser/package.json" | grep -q .; then
      rm -rf "${cacheDir}" "${prefixDir}"
    fi

    mkdir -p "${cacheDir}" "${prefixDir}/lib"
    export npm_config_cache="${cacheDir}"
    export npm_config_prefix="${prefixDir}"

    export AGENT_BROWSER_EXECUTABLE_PATH="${pkgs.chromium}/bin/chromium"
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

    if [ -z "''${SHELL:-}" ]; then
      export SHELL="${pkgs.bashInteractive}/bin/bash"
    fi

    exec ${pkgs.nodejs}/bin/npx --yes agent-browser@${version} "$@"
  '';
in {
  options.programs.cli-agents.agent-browser = {
    enable = mkEnableOption "agent-browser CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [package];
  };
}
