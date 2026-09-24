# System-level Instructions

RFC 2119 terminology applies only to uppercase keywords: MUST, REQUIRED, SHOULD, RECOMMENDED, MAY, OPTIONAL. NEVER = MUST NOT; AVOID = SHOULD NOT.
 
## Style

- Use Simple Technical English
- Use bullet points (e.g. for pro/con lists, or explanations of different approaches)
- NEVER include AI attribution (Co-Authored-By, "Generated with Claude Code", "Made-with: Cursor" etc.) in PRs.
- When explaining an API, show only the function signatures, not their bodies. Keep the focus on the surface (names, parameters, return types).
- When a design or interface proposal is relevant, present at least one concrete option and recommend a default when the tradeoffs support one.
- When explaining an API or brainstorming an interface, include a concise callstack-style tree by default. Use either a plain tree or an annotated tree with inline notes on calls when their responsibility is not obvious. Omit it only when there is no meaningful execution flow to show.
- When explaining, use diagrams (only if they make sense). Use Mermaid if a tool is available, otherwise use ASCII.
  - Don't use diagrams if it can be displayed with bullet points (since it's easier to understand and less verbose).
- When writing, reviewing, or refactoring code, load `code-style`

## Rules

- MUST fix the root cause of a bug rather than patching the symptoms. When in doubt, ask the user for more context.
- When writing public artifacts (issues, PRs, commit messages, public docs): NEVER include internal Slack threads, private channel discussions, internal doc links, internal tool or roadmap details, or teammate names. Describe the technical problem generically and cite only public sources; if an internal reference seems necessary, ask the user first.
- When you need to ask the user a question, you MUST use an available question tool. Prefer `ask_open_question` when it is available and predefined options would constrain the answer; otherwise use the option-based ask tool. NEVER substitute plain text output for a question tool call.
- NEVER reply to pull requests/review comments/GitHub issues/etc. unless the user asks you to

## Documentation

- Put temporary investigation and design artifacts in `.agents/docs/`, with filenames prefixed by the current date in YYYY-MM-DD format.
- Put other temporary files in `.agents/` and intermediate scripts in `.agents/scripts/`.
- Keep maintained project documentation, such as READMEs, in its established location.
- Do not create or update `.agents/docs` artifacts unless requested; they are point-in-time records.

NEVER reference files in `.agents` within source code (e.g. comments) or public artifacts (e.g. pull requests) as they are gitignored and meant to be development artifacts.

## Available CLI Tools

- **Core:** gh, rg (ripgrep), fd, eza, git, delta
- **System Info:** du-dust, duf, hexyl, tealdeer
- **Navigation:** When the user references a project or directory by name (e.g. "save this to dotfiles", "open apollo", "check the logs in my-service"), use zoxide (`z <name>`) to resolve the full path. Zoxide tracks frecency so partial names usually resolve correctly. Use it any time you need to locate a directory — navigating, saving files, reading from it, etc.
- **NixOS:** When a program isn't installed use `nix-shell` or `nix run`
- For throwaway Bash scripts, use a `#! nix-shell` shebang to declare required tools instead of assuming they are installed. Prefer running commands through `nix-shell -p` so missing tools do not cause avoidable failures.
