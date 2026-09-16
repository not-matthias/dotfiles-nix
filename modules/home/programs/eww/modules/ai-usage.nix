{pkgs}: let
  runtimeDeps = [pkgs.jq pkgs.curl pkgs.coreutils pkgs.bc pkgs.gnugrep pkgs.oh-my-pi];
  runtimePath = pkgs.lib.makeBinPath runtimeDeps;
  commonLib = ./scripts/ai-usage-common.sh;
  refreshSeconds = 600;
  refreshEnv = ''export AI_USAGE_REFRESH_SECONDS="${toString refreshSeconds}"'';

  mkUsageScript = name: script:
    pkgs.writeShellScriptBin name ''
      export PATH="${runtimePath}:$PATH"
      export AI_USAGE_COMMON="${commonLib}"
      export AI_USAGE_RETRY_LIMIT="5"
      ${refreshEnv}
      exec ${pkgs.bash}/bin/bash ${script}
    '';
in {
  claudeScript = mkUsageScript "eww-claude-usage" ./scripts/claude-usage.sh;
  codexScript = mkUsageScript "eww-codex-usage" ./scripts/codex-usage.sh;
  antigravityScript = mkUsageScript "eww-antigravity-usage" ./scripts/antigravity-usage.sh;
}
