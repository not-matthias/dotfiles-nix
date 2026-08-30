# System-level Instructions

## Style

- Use bullet points (e.g. for pro/con lists, or explanations of different approaches)
- NEVER include AI attribution (Co-Authored-By, "Generated with Claude Code", "Made-with: Cursor" etc.) in commits or PRs.
- When explaining an API, show only the function signatures, not their bodies. Keep the focus on the surface (names, parameters, return types).
- When a design or interface proposal is relevant, present at least one concrete option and recommend a default when the tradeoffs support one.
- When explaining an API or brainstorming an interface, include a concise callstack-style tree by default. Use either a plain tree or an annotated tree with inline notes on calls when their responsibility is not obvious. Omit it only when there is no meaningful execution flow to show.

  ```rust
  // Good — signatures only
  fn connect(addr: SocketAddr) -> Result<Connection>;
  fn send(&self, msg: &Message) -> Result<()>;
  fn close(self) -> Result<()>;

  // Avoid — inlining full implementations when only explaining the surface
  fn connect(addr: SocketAddr) -> Result<Connection> {
      let socket = TcpStream::connect(addr)?;
      // ...20 more lines...
  }
  ```

- When explaining, use diagrams (only if they make sense). Use Mermaid if a tool is available, otherwise use ASCII.
    - Don't use diagrams if it can be displayed with bullet points (since it's easier to understand and less verbose).
    - Prefer to use trees and bullet points in 90% of the cases, only use Mermaid in the other 10%.
- Use Simple Technical English

## Code Style

- **Minimize nesting:** Use early returns and inverted conditionals instead of deeply nested structures.
- **Max nesting depth:** 2-3 levels deep. Avoid 4+ level nesting.
- **Fail loudly:** Make it obvious when something goes wrong. Don't silently ignore errors or edge cases.
    - However, this doesn't mean that you have to handle all the error cases. Only handle what can actually occur.
- **IMPORTANT**: Comments must not narrate the specific feature, caller, or task that prompted a change — that ties the comment to one use case and it goes stale as soon as other code relies on the same logic. Explain the general mechanism when it is non-obvious; otherwise omit the comment. Match the comment density of the surrounding code.
- Comments explain WHY or a non-obvious invariant, never WHAT.
- Use ASCII diagrams in comments when it can improve understanding:
  - e.g.

    ```
    // Find the two buffers:
    //
    //  code_buffer                   data_buffer
    //  |-------|         |---------------------------------|
    //  | .text | padding | .rdata | .data | other sections |
    ```
- Struct field doc comments only on complex types. Not on trivial fields.

### Rust File & Module Layout

- Prefer a tree-like module structure: `<name>/mod.rs` with submodules as sibling files in the directory. A flat `<name>.rs` is fine when a module is genuinely tiny.
- Keep each `.rs` file small. Avoid putting many structs into a single file; split related types into sibling files.
- Prefer attaching functions to structs (methods/associated functions) over standalone free functions.
- In `mod.rs`, just declare/export the submodules (`pub mod foo;`). Don't re-export individual functions/structs (`pub use foo::Bar;`).
- Group `impl` blocks by concern (e.g. construction, trait impls, public API) rather than one giant block.

## Code Simplicity

- When writing, reviewing, or refactoring code, use the cognitive-load guidance in the `code-style` skill.
- Preserve behavior, but prefer simpler control flow, named conditions, local reasoning, and abstractions that reduce rather than add indirection.

## Rules

- ALWAYS fix the root cause of a bug rather than patching the symptoms. When in doubt, ask the user for more context.
- When using Rust: Always reduce nesting. Use `let-else` and early returns rather than multiple nested `if let` statements
- When using Python: Always use `uv`
- When working with Github: Use the `gh` and `git` CLI rather than fetching it manually
  - For PR comments, use: `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments`
  - Example: `gh api repos/not-matthias/apollo/pulls/154/comments`
- When committing: Always use semantic commit messages (e.g. `feat: add new feature`)
- When writing public artifacts (issues, PRs, commit messages, public docs): NEVER include internal Slack threads, private channel discussions, internal doc links, internal tool or roadmap details, or teammate names. Describe the technical problem generically and cite only public sources; if an internal reference seems necessary, ask the user first.
- When you need to ask the user a question, ALWAYS use the ask user question tool. NEVER substitute plain text output for a structured question tool call.
- NEVER reply to pull requests/review comments/GitHub issues/etc. unless the user asks you to
- IMPORTANT: NEVER use squash merge for PRs, ALWAYS use rebase merge

## Documentation

- Prefix all documentation entries with the current date in YYYY-MM-DD format and put them into the `.agents/docs` directory.
- Put all the temporary files and documentation you create into the `.agents` folder (e.g. `.agents/docs/2025-09-13-add-button.md`, ...).
- Store any intermediate scripts (shell scripts, Python scripts, etc.) in the `.agents/scripts/` folder.
- When changing code, don't update the .agents/docs unless the user asked you to, as they are meant to be point-in-time artifacts

Never reference files in `.agents` within source code (e.g. comments) or public artifacts (e.g. pull requests) as they are gitignored and meant to be development artifacts.

## Available CLI Tools

- **Core:** gh, rg (ripgrep), fd, eza, git, delta
- **System Info:** du-dust, duf, hexyl, tealdeer
- **Python:** ALWAYS use uv for all Python package and environment operations.
- **Navigation:** When the user references a project or directory by name (e.g. "save this to dotfiles", "open apollo", "check the logs in my-service"), use zoxide (`z <name>`) to resolve the full path. Zoxide tracks frecency so partial names usually resolve correctly. Use it any time you need to locate a directory — navigating, saving files, reading from it, etc.
- **NixOS:** When a program isn't installed use `nix-shell` or `nix run`
- For throwaway Bash scripts, use a `#! nix-shell` shebang to declare required tools instead of assuming they are installed. Prefer running commands through `nix-shell -p` so missing tools do not cause avoidable failures.
- Use `trash-put` instead of `rm` to avoid accidental data loss.
