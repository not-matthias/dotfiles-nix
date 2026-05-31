# System-level Instructions

## Style

- When explaining, always use diagrams if they make sense. Use Mermaid if a tool is available, otherwise use ASCII.
- Use bullet points (e.g. for pro/con lists, or explanations of different approaches)

## Code Style

- **Minimize nesting:** Use early returns and inverted conditionals instead of deeply nested structures.
- **Max nesting depth:** 2-3 levels deep. Avoid 4+ level nesting.
- **Fail loudly:** Make it obvious when something goes wrong. Don't silently ignore errors or edge cases.

## Rules

- When using Rust: Always reduce nesting. Use `let-else` and early returns rather than multiple nested `if let` statements
- When using Python: Always use `uv`
- When working with Github: Use the `gh` and `git` CLI rather than fetching it manually
  - For PR comments, use: `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments`
  - Example: `gh api repos/not-matthias/apollo/pulls/154/comments`
- When committing: Always use semantic commit messages (e.g. `feat: add new feature`)
- When you need to ask the user a question, ALWAYS use the `AskUserQuestion` tool if it is available in your toolset. Never substitute plain text output for a structured question tool call.

## Documentation

- Prefix all documentation entries with the current date in YYYY-MM-DD format and put them into the `.agents/docs` directory.
- Put all the temporary files and documentation you create into the `.agents` folder (e.g. `.agents/docs/2025-09-13-add-button.md`, ...).
- Store any intermediate scripts (shell scripts, Python scripts, etc.) in the `.agents/scripts/` folder.

## Available CLI Tools

- **Core:** gh, rg (ripgrep), fd, eza, git, delta
- **System Info:** du-dust, duf, hexyl, tealdeer
- **Python:** ALWAYS use uv for all Python package and environment operations.
- **Navigation:** When the user references a project or directory by name (e.g. "save this to dotfiles", "open apollo", "check the logs in my-service"), use zoxide (`z <name>`) to resolve the full path. Zoxide tracks frecency so partial names usually resolve correctly. Use it any time you need to locate a directory — navigating, saving files, reading from it, etc.
- **NixOS:** When a program isn't installed use `nix-shell` or `nix run`
- Use `trash-put` instead of `rm` to avoid accidental data loss.

## Testing

- When writing code: Use red-green testing (write a failing test first, make it pass, refactor).
- When fixing a bug: Write a test that reproduces the bug before fixing it.
