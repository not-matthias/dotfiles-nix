#!/usr/bin/env python3
"""Export the current Claude Code conversation to a GitHub Gist as markdown."""

import json
import sys
import os
import glob
import subprocess
from collections import Counter
from datetime import datetime
from pathlib import Path


def find_current_conversation(project_dir: str) -> str | None:
    """Find the most recently modified conversation JSONL file."""
    pattern = os.path.join(project_dir, "*.jsonl")
    files = glob.glob(pattern)
    if not files:
        return None
    return max(files, key=os.path.getmtime)


def extract_message_parts(content) -> tuple[str, list[str]]:
    """Extract prose text and tool call names from message content.

    Returns (prose_text, tool_names).
    """
    if isinstance(content, str):
        return content, []

    prose_parts = []
    tool_names = []

    for block in content:
        if not isinstance(block, dict):
            continue
        btype = block.get("type", "")
        if btype == "text":
            prose_parts.append(block["text"])
        elif btype == "tool_use":
            tool_names.append(block.get("name", "unknown"))
        # Skip tool_result and thinking blocks

    return "\n\n".join(prose_parts), tool_names


def convert_to_markdown(jsonl_path: str) -> str:
    """Convert a conversation JSONL file to readable markdown."""
    messages = []
    with open(jsonl_path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            msg_type = obj.get("type")
            if msg_type not in ("user", "assistant"):
                continue
            # Skip sidechain messages
            if obj.get("isSidechain"):
                continue
            messages.append(obj)

    if not messages:
        return "# Empty conversation\n"

    # Get metadata from first message
    first = messages[0]
    session_id = first.get("sessionId", "unknown")
    timestamp = first.get("timestamp", "")
    project = first.get("cwd", "")
    branch = first.get("gitBranch", "")

    lines = [
        f"# Claude Code Conversation",
        f"",
        f"- **Session**: `{session_id}`",
        f"- **Project**: `{project}`",
        f"- **Branch**: `{branch}`",
        f"- **Started**: {timestamp}",
        f"",
        f"---",
        f"",
    ]

    for obj in messages:
        msg_type = obj["type"]
        msg = obj.get("message", {})
        content = msg.get("content", "")

        if msg_type == "user":
            text, _ = extract_message_parts(content)
            prose = text.strip()
            if prose:
                # Inline for single-line, block for multi-line
                if "\n" in prose:
                    lines.append(f"**You:**\n\n{prose}")
                else:
                    lines.append(f"**You:** {prose}")
                lines.append(f"")
                lines.append(f"---")
                lines.append(f"")
        elif msg_type == "assistant":
            text, tool_names = extract_message_parts(content)
            prose = text.strip()
            if prose or tool_names:
                if prose:
                    if "\n" in prose:
                        lines.append(f"**Claude:**\n\n{prose}")
                    else:
                        lines.append(f"**Claude:** {prose}")
                if tool_names:
                    # Summarize tool calls without listing each individually
                    counts = Counter(tool_names)
                    summary = ", ".join(
                        f"{name} × {n}" if n > 1 else name
                        for name, n in counts.most_common()
                    )
                    lines.append(f"")
                    lines.append(f"*[tool calls: {summary}]*")
                lines.append(f"")
                lines.append(f"---")
                lines.append(f"")

    return "\n".join(lines)


def upload_gist(content: str, filename: str, description: str) -> str:
    """Upload content as a GitHub Gist and return the URL."""
    import tempfile

    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(content)
        tmp_path = f.name

    try:
        result = subprocess.run(
            ["gh", "gist", "create", tmp_path, "--desc", description, "--filename", filename],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            print(f"Error creating gist: {result.stderr}", file=sys.stderr)
            sys.exit(1)
        return result.stdout.strip()
    finally:
        os.unlink(tmp_path)


def main():
    # Determine the project conversations directory
    cwd = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    # Claude Code encodes the path by replacing / with -
    encoded = cwd.replace("/", "-")
    project_dir = os.path.expanduser(f"~/.claude/projects/{encoded}")

    if not os.path.isdir(project_dir):
        print(f"No conversation directory found at {project_dir}", file=sys.stderr)
        sys.exit(1)

    # Allow passing a specific session ID, or find the latest
    if len(sys.argv) > 1:
        session = sys.argv[1]
        jsonl_path = os.path.join(project_dir, f"{session}.jsonl")
        if not os.path.exists(jsonl_path):
            print(f"Session file not found: {jsonl_path}", file=sys.stderr)
            sys.exit(1)
    else:
        jsonl_path = find_current_conversation(project_dir)
        if not jsonl_path:
            print("No conversations found", file=sys.stderr)
            sys.exit(1)

    session_id = Path(jsonl_path).stem
    print(f"Converting session: {session_id}")

    markdown = convert_to_markdown(jsonl_path)

    now = datetime.now().strftime("%Y-%m-%d-%H%M")
    filename = f"claude-conversation-{now}.md"
    description = f"Claude Code conversation export ({now})"

    url = upload_gist(markdown, filename, description)
    print(f"Gist created: {url}")


if __name__ == "__main__":
    main()
