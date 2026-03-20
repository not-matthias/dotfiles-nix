# System-level Instructions

## Rules

These are non-negotiable rules that you MUST follow at all times. They override any other instructions.

1. **NEVER GUESS:** If you are less than 100% certain about any file's contents, a project requirement, or an API's behavior, you MUST STOP and ask for the specific information you need.
2. **WORKING CODE ONLY:** You MUST NOT provide placeholder, example, or incomplete code snippets. Every line of code you write must be part of a complete, working solution.
3. **PREFER EDITING:** You MUST always prefer editing existing files over creating new ones, unless a new file is explicitly required for the task.
4. **ADHERE TO PROTOCOL:** You MUST follow the workflow, communication, and documentation standards defined in this document.

## Approval Gates (only if the user asks for it)

When the users asks you to **propose** changes, or if they want to **approve** a change:

1. **Investigate Independently:** Research the codebase, identify relevant files, and analyze possible solutions without asking first.
2. **Present Your Plan:** Clearly describe:
   - What you found
   - Your proposed solution(s)
   - Why you think this approach is best
   - Any trade-offs or risks
3. **Await Approval:** STOP and wait for explicit confirmation from the user before writing any code or executing commands.
4. **Proceed After Green Light:** Only after the user approves can you implement.

This ensures alignment and prevents wasted work on rejected approaches.

## Communication

- **Asking questions:** When you need to ask the user a question, ALWAYS use the `AskUserQuestion` tool if it is available in your toolset. Never substitute plain text output for a structured question tool call.

## Code Style

<critical>
Write extremely easy to consume code. Optimize for how easy the code is to read. Make the code skimmable. Avoid cleverness. Use early returns. This is the single most important code style rule.
</critical>

- **Minimize nesting:** Use early returns and inverted conditionals instead of deeply nested structures.
- **Max nesting depth:** 2-3 levels deep. Avoid 4+ level nesting.

## Conditional Rules

- When using Rust: Always reduce nesting. Use `let-else` and early returns rather than multiple nested `if let` statements
- When using Python: Always use `uv`
- When working with Github: Use the `gh` and `git` CLI rather than fetching it manually
  - For PR comments, use: `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments`
  - Example: `gh api repos/not-matthias/apollo/pulls/154/comments`
- When committing: Always use semantic commit messages (e.g. `feat: add new feature`)

## Documentation

- Put all the temporary files and documentation you create into the `.agents` folder (e.g. `.agents/SCRATCHPAD.md`, `.agents/docs/2025-09-13-add-button.md`, ...).
- Prefix all documentation entries with the current date in YYYY-MM-DD format and put them into the `.agents/docs` directory.
- Store any intermediate scripts (shell scripts, Python scripts, etc.) in the `.agents/scripts/` folder.

## Available CLI Tools

- **Core:** gh, rg (ripgrep), fd, eza, git, delta
- **System Info:** du-dust, duf, hexyl, tealdeer
- **Python:** ALWAYS use uv for all Python package and environment operations.
- **Navigation:** When the user references a project or directory by name (e.g. "save this to dotfiles", "open apollo", "check the logs in my-service"), use zoxide (`z <name>`) to resolve the full path. Zoxide tracks frecency so partial names usually resolve correctly. Use it any time you need to locate a directory — navigating, saving files, reading from it, etc.
- **NixOS:** When a program isn't installed use `nix-shell` or `nix run`

## Testing

- When writing code: Use red-green testing (write a failing test first, make it pass, refactor).
- When fixing a bug: Write a test that reproduces the bug before fixing it.
