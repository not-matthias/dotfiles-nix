# System-level Instructions

## Style

- When explaining, always use diagrams if they make sense. Use Mermaid if a tool is available, otherwise use ASCII.
- Use bullet points (e.g. for pro/con lists, or explanations of different approaches)
- NEVER include AI attribution (Co-Authored-By, "Generated with Claude Code","Made-with: Cursor" etc.) in commits or PRs.
- When explaining an API, show only the function signatures, not their bodies. Keep the focus on the surface (names, parameters, return types).

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

## Code Style

- **NEVER** write comments!
- **Minimize nesting:** Use early returns and inverted conditionals instead of deeply nested structures.
- **Max nesting depth:** 2-3 levels deep. Avoid 4+ level nesting.
- **Fail loudly:** Make it obvious when something goes wrong. Don't silently ignore errors or edge cases.
- **IMPORTANT**: Comments must not narrate the specific feature, caller, or task that prompted a change — that ties the comment to one use case and it goes stale as soon as other code relies on the same logic. Explain the general mechanism when it is non-obvious; otherwise omit the comment. Match the comment density of the surrounding code.
  - By default, avoid adding comments.
- Comments explain WHY or a non-obvious invariant, never WHAT.
  - e.g. "The buffer must be in nonpageable memory, otherwise we will bluescreen with `IRQL_NOT_LESS_OR_EQUAL`."
- ASCII diagrams for memory layouts — used freely as comments when spatial relationships matter.
  - e.g.

    ```
    // Find the two buffers:
    //
    //  code_buffer                   data_buffer
    //  |-------|         |---------------------------------|
    //  | .text | padding | .rdata | .data | other sections |
    //
    // Padding is included in .text (at the end)
    //
    ```
- Struct field doc comments only on complex types. Not on trivial fields.

### Rust File & Module Layout

- Prefer a tree-like module structure: `<name>/mod.rs` with submodules as sibling files in the directory. A flat `<name>.rs` is fine when a module is genuinely tiny.
- Keep each `.rs` file small. Avoid putting many structs into a single file; split related types into sibling files.
- Prefer attaching functions to structs (methods/associated functions) over standalone free functions.
- In `mod.rs`, just declare/export the submodules (`pub mod foo;`). Don't re-export individual functions/structs (`pub use foo::Bar;`).
- Group `impl` blocks by concern (e.g. construction, trait impls, public API) rather than one giant block.

## Code Simplicity

- When writing, reviewing, or refactoring code, use the `cognitive-load` skill.
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
- When you need to ask the user a question, ALWAYS use the `AskUserQuestion` tool if it is available in your toolset. Never substitute plain text output for a structured question tool call.

## Documentation

- Prefix all documentation entries with the current date in YYYY-MM-DD format and put them into the `.agents/docs` directory.
- Put all the temporary files and documentation you create into the `.agents` folder (e.g. `.agents/docs/2025-09-13-add-button.md`, ...).
- Store any intermediate scripts (shell scripts, Python scripts, etc.) in the `.agents/scripts/` folder.

Never reference files in `.agents` within source code (e.g. comments) as they are gitignored and meant to be development artifacts.

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

## Subagents

You have three different tools to start subagents:

- "I need a senior engineer to think with me" -> Oracle
- "I need to find code that matches a concept" -> Codebase Search Agent
- "I know what to do, need large multi-step execution" -> Task Tool

## Self-improving

- At the end of each session, reflect on what went well and what could be improved. Update AGENTS.md/CLAUDE.md with any new insights or rules you want to follow in the future.
