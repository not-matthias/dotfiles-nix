---
name: omp-ttsr-rules
description: Create and validate Oh My Pi TTSR rules. Use when asked to add a stream rule, prevent a recurring agent mistake, or fix a rule that does not trigger or triggers too broadly.
---

# Omp TTSR Rules

Turn a recognizable mistake into a narrowly scoped trigger and an actionable correction. Use omp's native matcher to verify it; do not implement a second matcher. Assume the documented commands are available; do not check the omp version.

## Choose the rule

- Identify the forbidden output, the allowed alternative, and the surface where the mistake occurs: prose, thinking, a shell command, or introduced source code.
- Gather a positive example for every proposed condition and realistic allowed near-misses before writing the rule.
- Use TTSR for detectable, occasional mistakes. Use always-on instructions for general guidance; use deterministic tool interception for a hard execution boundary. TTSR cannot undo completed actions and normally fires only once per session.
- Prefer a distinctive regex for commands or phrases, and `astCondition` for structural code patterns whose formatting or identifiers vary. Avoid broad keywords and nested ambiguous repetition such as `(.*)+`.
- Keep one concern per rule. The Markdown body should state the constraint and a useful alternative, not repeat the trigger or narrate the incident that prompted it.

## Write the file

Use a unique, descriptive filename. Discovery derives the rule name from the filename, not frontmatter `name`. Native project rules win over native user rules with the same name.

- Project rule: `.omp/rules/<name>.md` or `.mdc` at the project root.
- Personal rule: the active profile's rules directory, normally `~/.omp/agent/rules/` (affected by `PI_CODING_AGENT_DIR`).
- In dotfiles-nix, edit the declarative personal-rule source at `modules/home/programs/cli-agents/oh-my-pi/rules/`, not its Home Manager-managed destination. Test the source file directly before activation.

Minimal regex example, saved as `no-box-leak.md`:

```markdown
---
description: Avoid permanent Box::leak allocations in Rust edits
condition: '\bBox::leak\s*\('
scope:
  - 'tool:edit(*.rs)'
  - 'tool:write(*.rs)'
interruptMode: always
---

Do not introduce `Box::leak`. Keep ownership explicit and choose an owned value
or shared ownership appropriate to the required lifetime.
```

For a structural TypeScript rule, use these fields instead:

```yaml
astCondition: '$VALUE as any'
scope:
  - 'tool:edit(*.ts)'
  - 'tool:write(*.ts)'
```

### Matching contract

- `condition` is a JavaScript regex string or list. Leading `(?i)`, `(?m)`, and `(?s)` flags are supported. Use single-quoted YAML strings to preserve backslashes; do not wrap regexes in `/.../` delimiters.
- `astCondition` is an ast-grep pattern string or list. It matches source-bearing edit/write content with a recognizable file extension, not prose or unchanged code elsewhere in the file.
- Conditions are alternatives: any regex OR any AST pattern can trigger after scope and path gates pass. A list does not mean AND.
- Use explicit `scope` lists. Tokens include `text`, `thinking`, `tool`, `tool:bash`, and `tool:edit(src/**/*.ts)`. An explicit list replaces the default of text plus all tools, excluding thinking.
- `globs` is an additional path gate. Without a matching candidate path the rule cannot fire, even if its scope allows text or a shell tool. Path matching includes normalized paths and basenames.
- Edit/write regexes see introduced source content; other tools generally expose streamed arguments. Match the actual tool surface, not an imagined whole file or command AST. A shell regex can also match quoted examples inside a command.
- Avoid glob shorthand in `condition`: `condition: '*.rs'` becomes a catch-all condition scoped to Rust edit/write calls. Put path restrictions in `scope` or `globs` instead.
- Use `interruptMode: always` when the matched action must not proceed. `never` allows a tool to finish and supplies a reminder afterward; `prose-only` and `tool-only` interrupt only their named surfaces. Omitting the field inherits the global setting.
- Do not combine TTSR triggers with `alwaysApply` to request both behaviors: a registered TTSR rule is excluded from the always-apply bucket.
- Keep secrets out of the body: it is sent to the model when the rule fires and can persist in session history.

## Validate the rule

### 1. Check the document

Require well-formed YAML frontmatter starting on the first line, closing `---`, at least one non-empty `condition` or `astCondition`, valid field types, and a non-empty corrective body. Reject misspelled fields and invalid interrupt modes rather than relying on defaults. Use a strict YAML parser if the syntax is uncertain.

Loading is not strict validation. The frontmatter parser can recover partial metadata from malformed YAML. Registration logs and drops invalid regexes individually; one usable condition can keep a broken multi-condition rule registered. AST patterns are accepted at registration and matching errors become non-matches.

### 2. Exercise every condition in isolation

Run `omp ttsr test --rule` with explicit context. For the example above:

```bash
omp ttsr test --rule .omp/rules/no-box-leak.md --json \
  --source tool --tool edit --path src/lib.rs \
  'let value = Box::leak(Box::new(input));'

omp ttsr test --rule .omp/rules/no-box-leak.md --json \
  --source tool --tool edit --path src/lib.rs \
  'let value = Box::new(input);'
```

- Require a positive case for **every declared regex and AST condition**, plus an in-scope negative case. Prefer examples that distinguish conditions. If conditions overlap, make a temporary copy with only the condition being tested and run the same native command against it.
- For each positive case, assert the target rule appears in JSON `triggered` and the intended pattern appears in that entry's `matched.regex` or `matched.ast`. For negative cases, assert it does not appear in `triggered`.
- Exit status alone does not prove a match. `matched` details also appear under `notTriggered` when a scope/path gate rejects the rule; those details are not successful triggers.
- Cover each intended tool and relevant path/language. Add wrong-tool, wrong-path, and wrong-source cases for restrictions the rule relies on. Thinking must be explicitly included if intended.
- Test allowed alternatives, quoted discussion, comments or strings where relevant, identifier substrings, and whitespace variants. Evaluate partial prefixes if a regex could fire before enough context arrives, especially patterns using end anchors or negative lookaheads.
- For AST conditions, supply `--source tool`, `--tool edit` or `write`, and `--path` with the intended extension. Test each supported language rather than assuming a pattern is portable.
- Use `--file <sample>` for larger samples or `--file -` for stdin. Explicit source/tool/path flags avoid the CLI's file-extension-based inference.
- Keep temporary samples and single-condition rule copies outside discovered rule directories, under `.agents/`; remove only those temporary files after verification.

The CLI exercises matching snapshots, not a live model retry or the corrective body's effectiveness. Do not claim end-to-end interruption from these checks alone.

### 3. Check discovery and false positives

After placing or activating the rule:

```bash
omp ttsr list --json
omp ttsr test --json --source tool --tool edit --path src/lib.rs \
  'let value = Box::leak(Box::new(input));'
```

- Confirm the filename-derived name and effective source path in `list`, then repeat a positive case without `--rule` so real discovery and settings are exercised. Inspect the target by name; unrelated rules may also trigger.
- For source-code rules, sample the relevant tree with `omp ttsr scan --rule <rule.md> src/`. Review hits as candidates, not proven violations. Scanning existing files is not a substitute for testing a shell/prose rule or incremental edits.
- If isolation works but discovery does not, inspect `ttsr.enabled`, `ttsr.disabledRules`, the active profile, and same-name shadowing. Do not silently change global settings to make the test pass.
- Start a new session after adding or changing rules. The default repeat policy is once per session and its fired state survives resume; isolated tests bypass that session history and project settings.
- If declarative activation has not happened, report source-file verification separately from installed discovery. Do not claim the new rule is active yet.

## Deliver

Report the file, intended trigger and scope, positive/negative results, and discovery or activation status. State any coverage limitation. Do not leave an unproven condition enabled or claim that a passing matcher test establishes hard safety enforcement.

<!-- Sources:
https://omp.sh/docs/ttsr
https://nibblebot.github.io/oh-my-pi/features/stream-rules/
Implementation: packages/coding-agent/src/discovery/helpers.ts; packages/coding-agent/src/capability/rule.ts; packages/coding-agent/src/export/ttsr.ts; packages/coding-agent/src/session/ttsr-coordinator.ts; packages/coding-agent/src/cli/ttsr-cli.ts; packages/utils/src/frontmatter.ts in https://github.com/can1357/oh-my-pi
-->
