{pkgs}: let
  script = pkgs.writeShellScriptBin "niri_window_index" ''
    update_display() {
        # Query niri for focused workspace
        WORKSPACE_OUTPUT=$(niri msg --json workspaces 2>/dev/null)
        FOCUSED_WS_ID=$(echo "$WORKSPACE_OUTPUT" | ${pkgs.jq}/bin/jq -r '.[] | select(.is_focused == true) | .id')

        if [ -z "$FOCUSED_WS_ID" ]; then
            echo '{"text": "", "tooltip": "No focused workspace", "class": "empty"}'
            return
        fi

        # Query niri for windows information
        WINDOWS_OUTPUT=$(niri msg --json windows 2>/dev/null)

        if [ -z "$WINDOWS_OUTPUT" ] || [ "$WINDOWS_OUTPUT" = "null" ]; then
            echo '{"text": "", "tooltip": "No windows", "class": "empty"}'
            return
        fi

        # Parse JSON to find focused window and count windows on focused workspace
        # Sort by horizontal position (pos_in_scrolling_layout[0])
        RESULT=$(echo "$WINDOWS_OUTPUT" | ${pkgs.jq}/bin/jq -r --arg ws_id "$FOCUSED_WS_ID" '
          . as $root |
          ($root | map(select(.workspace_id == ($ws_id | tonumber)))) as $ws_windows |
          ($ws_windows | sort_by(.layout.pos_in_scrolling_layout[0])) as $sorted_windows |
          ($sorted_windows | map(select(.is_focused == true)) | .[0]) as $focused |
          if ($sorted_windows | length) > 0 then
            if $focused then
              ($sorted_windows | map(.id) | index($focused.id)) as $idx |
              {
                index: $idx,
                total: ($sorted_windows | length)
              }
            else
              {
                index: -1,
                total: ($sorted_windows | length)
              }
            end
          else
            null
          end |
          if . then
            "\(.index)|\(.total)"
          else
            ""
          end
        ')

        if [ -n "$RESULT" ] && [ "$RESULT" != "null" ] && [ "$RESULT" != "" ]; then
            IFS='|' read -r INDEX TOTAL <<< "$RESULT"

            # Build dot visualization with spacing
            DOTS=""
            for ((i=0; i<TOTAL; i++)); do
                if [ $i -gt 0 ]; then
                    DOTS="$DOTS "
                fi
                if [ "$INDEX" != "-1" ] && [ $i -eq $INDEX ]; then
                    DOTS="$DOTS󰪥"
                else
                    DOTS="$DOTS󰄰"
                fi
            done

            if [ "$INDEX" != "-1" ]; then
                echo "{\"text\": \"$DOTS\", \"tooltip\": \"Window $INDEX/$TOTAL\", \"class\": \"active\"}"
            else
                echo "{\"text\": \"$DOTS\", \"tooltip\": \"$TOTAL windows\", \"class\": \"inactive\"}"
            fi
        else
            echo '{"text": "", "tooltip": "No windows", "class": "empty"}'
        fi
    }

    # Initial display
    update_display

    # Listen to niri event stream for changes
    niri msg event-stream 2>/dev/null | while read -r line; do
        case "$line" in
            "Window opened or changed:"*|"Window closed:"*|"Window focus changed:"*|"Workspace focused:"*|*"active window changed to"*)
                update_display
                ;;
        esac
    done
  '';
in {
  inherit script;

  # Module configuration for waybar settings
  config = {
    "custom/niri-window-index" = {
      return-type = "json";
      # FIXME: The dots are offset to the right which will make the padding not work correctly.
      #        We'll have to add an extra space on the right.
      format = " {text} ";
      exec = "${script}/bin/niri_window_index";
    };
  };
}
