{pkgs}:
pkgs.writeShellApplication {
  name = "quickshell-niri-state";
  runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.niri];
  text = ''
    emit_empty() {
      printf '%s\n' '{"workspaces":[],"windows":[],"language":""}'
    }

    refresh() {
      local workspaces windows layouts
      workspaces="$(${pkgs.niri}/bin/niri msg --json workspaces 2>/dev/null)" || {
        emit_empty
        return
      }
      windows="$(${pkgs.niri}/bin/niri msg --json windows 2>/dev/null)" || {
        emit_empty
        return
      }
      layouts="$(${pkgs.niri}/bin/niri msg --json keyboard-layouts 2>/dev/null)" || {
        emit_empty
        return
      }

      ${pkgs.jq}/bin/jq -cn \
        --argjson workspaces "$workspaces" \
        --argjson windows "$windows" \
        --argjson layouts "$layouts" '
          ($workspaces | map(select(.is_focused)) | .[0]
            // (map(select(.is_active)) | .[0])
            // .[0]) as $focused
          | ($focused.output // null) as $output
          | ($layouts.names[$layouts.current_idx] // "") as $layout
          | {
              workspaces: ([
                $workspaces[]
                | select($output != null and .output == $output)
                | select(.name != null)
                | {
                    id,
                    idx,
                    name,
                    is_active,
                    is_focused,
                    is_urgent
                  }
              ] | sort_by(.idx)),
              windows: (
                if $focused == null then []
                else [
                  $windows[]
                  | select(.workspace_id == $focused.id and (.is_floating | not))
                  | {
                      id,
                      is_focused,
                      position: (.layout.pos_in_scrolling_layout[0] // 0)
                    }
                ]
                | sort_by(.position)
                | map(del(.position))
                end
              ),
              language: (
                if $layout == "English (US)" then "en"
                elif $layout == "German" then "de"
                else $layout
                end
              )
            }'
    }

    while :; do
      refresh
      ${pkgs.coreutils}/bin/sleep 1
    done
  '';
}
