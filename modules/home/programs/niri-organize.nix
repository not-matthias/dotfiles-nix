{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.niri-organize;

  # Main monitor to move workspaces to
  mainMonitor = "DP-3";

  # Workspace rules: app-id regex -> workspace name
  # Mirrors the window-rules in niri config
  workspaceRules = [
    {
      workspace = "web";
      appIds = ["^firefox$" "floorp" "^zen-browser$" "^brave$" "^chromium$" "^librewolf$" "^google-chrome$" "^chrome-"];
    }
    {
      workspace = "code";
      appIds = ["^code$" "^VSCodium$" "^dev\\.zed\\.Zed$" "^neovide$"];
    }
    {
      workspace = "notes";
      appIds = ["^obsidian$" "^logseq$" "^notion$"];
    }
    {
      workspace = "chat";
      appIds = ["^discord$" "^Discord$" "^slack$" "^element$" "^telegram$" "^BeeperTexts$"];
    }
    {
      workspace = "music";
      appIds = ["^spotify$" "^Spotify$" "^feishin$"];
    }
  ];

  # Desired workspace order (first = topmost)
  desiredOrder = map (r: r.workspace) workspaceRules;

  jq = "${pkgs.jq}/bin/jq";
  niri = "niri";

  package = pkgs.writeShellScriptBin "niri-organize" ''
    set -euo pipefail

    MAIN_MONITOR="${mainMonitor}"

    echo "=== Moving workspaces to $MAIN_MONITOR ==="

    # Get all workspaces not on the main monitor
    workspaces=$(${niri} msg -j workspaces)
    echo "$workspaces" | ${jq} -r --arg mon "$MAIN_MONITOR" \
      '.[] | select(.output != $mon and .name != null) | .name' | while read -r ws_name; do
      ${niri} msg action focus-monitor "$( echo "$workspaces" | ${jq} -r --arg name "$ws_name" '.[] | select(.name == $name) | .output' )"
      ${niri} msg action focus-workspace "$ws_name"
      ${niri} msg action move-workspace-to-monitor "$MAIN_MONITOR"
      echo "  Moved workspace '$ws_name' to $MAIN_MONITOR"
    done

    echo ""
    echo "=== Organizing windows ==="

    # Get all windows as JSON
    windows=$(${niri} msg -j windows)

    # Process each window
    echo "$windows" | ${jq} -c '.[]' | while read -r win; do
      win_id=$(echo "$win" | ${jq} -r '.id')
      app_id=$(echo "$win" | ${jq} -r '.app_id')
      title=$(echo "$win" | ${jq} -r '.title')
      target_ws=""

      ${lib.concatMapStringsSep "\n" (rule: ''
        if [ -z "$target_ws" ]; then
          ${lib.concatMapStringsSep "\n" (pattern: ''
            if [ -z "$target_ws" ] && echo "$app_id" | grep -qE '${pattern}'; then
              target_ws="${rule.workspace}"
            fi
          '')
          rule.appIds}
        fi
      '')
      workspaceRules}

      if [ -n "$target_ws" ]; then
        # Check if window is already on the correct workspace
        target_ws_id=$(${niri} msg -j workspaces | ${jq} -r --arg name "$target_ws" '.[] | select(.name == $name) | .id')
        current_ws_id=$(echo "$win" | ${jq} -r '.workspace_id')

        if [ "$current_ws_id" != "$target_ws_id" ]; then
          ${niri} msg action move-window-to-workspace --window-id "$win_id" --focus false "$target_ws"
          echo "  Moved '$title' ($app_id) -> $target_ws"
        else
          echo "  OK   '$title' ($app_id) already on $target_ws"
        fi
      else
        echo "  Skip '$title' ($app_id) - no matching rule"
      fi
    done

    echo ""
    echo "=== Reordering workspaces ==="

    # Push each workspace to the top in reverse desired order.
    # After the loop, the first desired workspace is at the top.
    max_moves=20
    for ws_name in ${lib.concatMapStringsSep " " (ws: ''"${ws}"'') (lib.reverseList desiredOrder)}; do
      ws_id=$(${niri} msg -j workspaces | ${jq} -r --arg name "$ws_name" --arg mon "$MAIN_MONITOR" \
        '.[] | select(.name == $name and .output == $mon) | .id')
      if [ -z "$ws_id" ]; then
        continue
      fi

      ${niri} msg action focus-workspace "$ws_name"
      for _ in $(seq 1 $max_moves); do
        ${niri} msg action move-workspace-up 2>/dev/null || true
      done
      echo "  Pinned '$ws_name' to top"
    done

    echo ""
    echo "Done!"
  '';
in {
  options.programs.niri-organize = {
    enable = mkEnableOption "niri-organize - move workspaces and windows to correct monitors";
  };

  config = mkIf cfg.enable {
    home.packages = [package];
  };
}
