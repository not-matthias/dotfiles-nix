{pkgs}: let
  runtimeDeps = [pkgs.jq pkgs.curl pkgs.coreutils pkgs.bc pkgs.gnugrep];
  runtimePath = pkgs.lib.makeBinPath runtimeDeps;
  umansRuntimePath = pkgs.lib.makeBinPath (runtimeDeps ++ [pkgs.umans]);
  commonLib = ./scripts/ai-usage-common.sh;
  # /api/oauth/usage aggressively 429s; see github.com/anthropics/claude-code/issues/30930.
  # Sourced from one place so the Waybar poll interval and the script cache TTL can't drift.
  refreshSeconds = 600;
  refreshEnv = ''export AI_USAGE_REFRESH_SECONDS="${toString refreshSeconds}"'';
  umansRefreshSeconds = 60;
  umansRefreshEnv = ''export AI_USAGE_REFRESH_SECONDS="${toString umansRefreshSeconds}"'';

  claudeScript = pkgs.writeShellScriptBin "waybar-claude-usage" ''
    export PATH="${runtimePath}:$PATH"
    export AI_USAGE_COMMON="${commonLib}"
    export AI_USAGE_RETRY_LIMIT="5"
    ${refreshEnv}
    exec ${pkgs.bash}/bin/bash ${./scripts/claude-usage.sh}
  '';

  codexScript = pkgs.writeShellScriptBin "waybar-codex-usage" ''
    export PATH="${runtimePath}:$PATH"
    export AI_USAGE_COMMON="${commonLib}"
    export AI_USAGE_RETRY_LIMIT="5"
    ${refreshEnv}
    exec ${pkgs.bash}/bin/bash ${./scripts/codex-usage.sh}
  '';

  umansScript = pkgs.writeShellScriptBin "waybar-umans-usage" ''
    export PATH="${umansRuntimePath}:$PATH"
    export AI_USAGE_COMMON="${commonLib}"
    export AI_USAGE_RETRY_LIMIT="1"
    ${umansRefreshEnv}
    exec ${pkgs.bash}/bin/bash ${./scripts/umans-usage.sh} "$@"
  '';
in {
  inherit claudeScript codexScript umansScript;

  config = {
    "custom/claude-usage" = {
      return-type = "json";
      format = "{}";
      exec = "${claudeScript}/bin/waybar-claude-usage";
      # pkill -RTMIN+8 makes waybar re-run exec immediately so the bar repaints
      # instead of waiting for the next interval after a manual refresh.
      on-click = "${claudeScript}/bin/waybar-claude-usage --force-refresh && ${pkgs.procps}/bin/pkill -RTMIN+8 waybar";
      on-click-right = "${claudeScript}/bin/waybar-claude-usage --restart && ${pkgs.procps}/bin/pkill -RTMIN+8 waybar";
      signal = 8;
      interval = refreshSeconds;
    };

    "custom/codex-usage" = {
      return-type = "json";
      format = "{}";
      exec = "${codexScript}/bin/waybar-codex-usage";
      on-click = "${codexScript}/bin/waybar-codex-usage --force-refresh && ${pkgs.procps}/bin/pkill -RTMIN+10 waybar";
      on-click-right = "${codexScript}/bin/waybar-codex-usage --restart && ${pkgs.procps}/bin/pkill -RTMIN+10 waybar";
      signal = 10;
      interval = refreshSeconds;
    };

    "custom/umans-usage" = {
      return-type = "json";
      format = "{}";
      exec = "${umansScript}/bin/waybar-umans-usage";
      on-click = "${umansScript}/bin/waybar-umans-usage --force-refresh && ${pkgs.procps}/bin/pkill -RTMIN+11 waybar";
      on-click-right = "${umansScript}/bin/waybar-umans-usage --restart && ${pkgs.procps}/bin/pkill -RTMIN+11 waybar";
      signal = 11;
      interval = umansRefreshSeconds;
    };
  };
}
