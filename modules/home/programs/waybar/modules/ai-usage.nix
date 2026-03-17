{pkgs}: let
  runtimeDeps = [pkgs.jq pkgs.curl pkgs.coreutils];
  runtimePath = pkgs.lib.makeBinPath runtimeDeps;
  commonLib = ./scripts/ai-usage-common.sh;

  claudeScript = pkgs.writeShellScriptBin "waybar-claude-usage" ''
    export PATH="${runtimePath}:$PATH"
    export AI_USAGE_COMMON="${commonLib}"
    export AI_USAGE_RETRY_LIMIT="5"
    exec ${pkgs.bash}/bin/bash ${./scripts/claude-usage.sh}
  '';

  codexScript = pkgs.writeShellScriptBin "waybar-codex-usage" ''
    export PATH="${runtimePath}:$PATH"
    export AI_USAGE_COMMON="${commonLib}"
    export AI_USAGE_RETRY_LIMIT="5"
    exec ${pkgs.bash}/bin/bash ${./scripts/codex-usage.sh}
  '';
in {
  inherit claudeScript codexScript;

  config = {
    "custom/claude-usage" = {
      return-type = "json";
      format = "{}";
      exec = "${claudeScript}/bin/waybar-claude-usage";
      on-click = "${claudeScript}/bin/waybar-claude-usage --force-refresh";
      on-click-right = "${claudeScript}/bin/waybar-claude-usage --restart";
      interval = 300; # /api/oauth/usage aggressively 429s — see github.com/anthropics/claude-code/issues/30930
    };

    "custom/codex-usage" = {
      return-type = "json";
      format = "{}";
      exec = "${codexScript}/bin/waybar-codex-usage";
      on-click = "${codexScript}/bin/waybar-codex-usage --force-refresh";
      on-click-right = "${codexScript}/bin/waybar-codex-usage --restart";
      interval = 300;
    };
  };
}
