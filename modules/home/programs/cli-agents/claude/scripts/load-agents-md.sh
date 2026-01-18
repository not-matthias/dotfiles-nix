#!/usr/bin/env bash
# Hook: Load AGENTS.md from the current project repository
#
# This script is triggered at SessionStart and attempts to find and load
# AGENTS.md from the current project directory. If found, it returns the
# file contents as additional context for the session.
#
# Context: https://github.com/anthropics/claude-code/issues/6235

set -euo pipefail

# Try to find AGENTS.md in the project directory
find_agents_md() {
    local current_dir="${CLAUDE_PROJECT_DIR}"

    # Check if we're in a valid project directory
    if [[ -z "$current_dir" ]] || [[ "$current_dir" == "/" ]]; then
        return 1
    fi

    # Look for AGENTS.md in the project root
    if [[ -f "$current_dir/AGENTS.md" ]]; then
        echo "$current_dir/AGENTS.md"
        return 0
    fi

    return 1
}

# Main logic
if agents_md_path=$(find_agents_md); then
    # File found, read it and return as JSON with systemMessage
    content=$(<"$agents_md_path")

    # Escape the content for JSON using jq and prepend header
    context_text="# Loaded from repository AGENTS.md

${content}"
    context_json=$(printf '%s' "$context_text" | jq -Rs .)

    # Return JSON response with the file content as systemMessage
    printf '{
  "systemMessage": %s
}' "$context_json"
else
    # No AGENTS.md found in project, return empty JSON
    # This allows the hook to exit gracefully without blocking the session
    printf '{}'
fi
