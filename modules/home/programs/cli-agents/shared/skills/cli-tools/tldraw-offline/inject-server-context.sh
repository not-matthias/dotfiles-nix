#!/bin/sh
# Optional Claude Code SubagentStart hook. NOT auto-wired by this skill — to
# enable auto-injection of the tldraw server URL + bearer token at subagent
# launch, register this script under the `hooks.SubagentStart` array in
# modules/home/programs/cli-agents/claude/settings.json. It prints nothing when
# the app is not running. Output is Claude-specific JSON
# ({hookSpecificOutput:{hookEventName,additionalContext}}); it has no effect on
# omp/codex/amp/opencode, which fall back to `tq` / reading server.json.
event="${1:-SubagentStart}"
server_json="$HOME/.config/tldraw/server.json"

command -v jq >/dev/null 2>&1 || exit 0
[ -f "$server_json" ] || exit 0

port=$(jq -r '.port // empty' "$server_json" 2>/dev/null) || exit 0
token=$(jq -r '.token // empty' "$server_json" 2>/dev/null) || exit 0
[ -n "$port" ] && [ -n "$token" ] || exit 0

context="The tldraw desktop canvas server is running at http://localhost:$port. Send the header 'Authorization: Bearer $token' on every request except GET / and /readme. Use these values directly — you do not need to read server.json."

# Snapshot the open documents so the agent starts knowing what canvases exist.
# Best-effort: a dead server, missing curl, or a slow response must not delay
# or fail the subagent launch.
docs=""
if command -v curl >/dev/null 2>&1; then
  docs=$(curl -s --max-time 2 -X POST "http://localhost:$port/api/search" \
    -H 'content-type: text/plain' \
    -H "authorization: Bearer $token" \
    --data-binary 'return await api.getDocs()' 2>/dev/null | jq -c '.result // empty' 2>/dev/null)
fi

if [ -n "$docs" ] && [ "$docs" != "[]" ]; then
  context="$context

The user's currently open tldraw offline canvases (most-recently-active first): $docs"
fi

jq -n --arg event "$event" --arg context "$context" \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
