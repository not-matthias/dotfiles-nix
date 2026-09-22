# Merge Review

Use when proposing a merge, generalization, relocation, or retirement. Inspect the source material before choosing a destination.

## Preserve the useful distinctions

Identify facts the model cannot safely reconstruct from general knowledge:

- Preconditions: runtime, version, permissions, host, working directory, input format.
- Exact commands, flags, environment variables, and failure signatures.
- Ordering constraints, destructive steps, restoration requirements, and verification methods.
- Counterexamples and rejected approaches that prevent a plausible repeat failure.
- Supporting scripts, fixtures, and source/license attribution.

Map each unique fact to a destination section or reference. A short per-source list is sufficient; do not create a tracking framework. For discarded material, state why it is duplicated, obsolete, incorrect, or merely a session narrative. Preserve the mechanism and applicable conditions, not incidental chronology or private task identifiers.

An error string can be a valuable lookup key even when the surrounding story is not. Generalization should remove unnecessary specificity, not the conditions that make an instruction correct.

## Choose a coherent parent

A common topic is not enough. Compare user intent, prerequisites, procedure, output, and safety boundaries.

- Same procedure with runtime-specific flags: common root plus runtime references.
- A special failure during a broader workflow: a conditional troubleshooting reference in that workflow.
- Two unrelated workflows sharing a helper: keep their entry points; extract only the common helper if the shared location will remain accessible.
- Conflicting authorization requirements: retain separate workflows or explicit branches; do not broaden permission by merging them.

Do not leave duplicate old entry points solely as aliases: they retain startup cost. Propose updating callers and registrations as part of the cutover, with approval for any externally relied-on name changes.

## Make references discoverable

The root should answer which branch applies without requiring every reference to be opened:

```markdown
## Choose the procedure

- For a normal package release, follow the steps below.
- For a prerelease channel, read [Prereleases](references/prereleases.md).
- To verify publish arguments without publishing, read [Offline verification](references/offline-verification.md).
```

A reference should contain the branch-specific details, not repeat the whole root workflow. Link all branch references directly from the root. Keep distinctive symptoms in the route text; put only the essential discovery terms in the skill description.

Consider the tradeoff explicitly: replacing several precise descriptions with one broad description saves startup context but adds a routing step. Report that cost; do not claim every merge improves selection.

## Resolve contradictions before deleting sources

Separate genuine disagreement from different environments. An instruction may be correct on one kernel, agent, or tool version and wrong on another.

For each conflict:

1. Record the competing claims and their applicability conditions.
2. Check current code, documentation, or safe observed behavior where accessible.
3. Keep scoped variants when both are valid.
4. Ask for a decision or leave the affected merge unapplied when evidence cannot resolve the conflict.

The newest file is not automatically authoritative. Do not silently combine incompatible commands or select whichever wording sounds more confident.

## Suggest canonical dotfiles-nix destinations
Keep managed consolidations in managed storage by default. Repository targets are separate suggestions requiring explicit approval; project-specific knowledge stays global unless scope changes are requested.


Inspect existing first-party skills under:

`modules/home/programs/cli-agents/shared/skills/`

Also inspect program-owned skill locations if the configuration registers them. Keep skills for optional programs gated with those programs rather than promoting them into an unconditional global catalog.

For each reusable source family:

- Look for an existing skill that owns the intent, not merely the same tool name.
- Read that target and its references before proposing additions.
- Prefer a focused reference within that target when the root already covers the common procedure.
- Suggest the exact target path, additions to its routing instructions, and source skills that could then disappear.
- Separate storage consolidation from discovery scope. Do not relocate project-specific skills merely because their names mention a repository.
- Leave third-party copies intact. If only an imported skill overlaps, propose a separate first-party companion or retaining the source, not a silent fork of the import.

Example proposal shape:

```text
Sources: <first-party skills with overlapping procedures>
Suggested target: <dotfiles-nix path to existing first-party skill>
Root change: <common procedure or new conditional route>
References: <file path -> retained variant and loading condition>
Remove after approval: <superseded source entry points>
Tradeoff: <startup saving, activation cost, discovery risk>
Unresolved: <contradictions or ownership restrictions>
```

## Avoid immediate regrowth

If this skill is invoked while adding a new lesson, check the existing library before creating another entry point:

- Existing workflow, new exception: suggest a reference update.
- Existing exception, better evidence: suggest correcting the canonical section.
- Genuinely distinct reusable intent: suggest a new first-party skill.
- Project-only fact: retain current scope unless the user requests relocation.

Do not install a background maintenance loop or modify automatic skill creation policy without an explicit request.
