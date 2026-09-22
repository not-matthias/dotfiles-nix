# Explicit Project-Local Relocation

Use only when the user requests changing discovery scope. Consolidation alone keeps managed skills global, including project-specific knowledge.

## Select and copy

- Resolve the repository using the project locator, not historical absolute paths. Prefixes and body keywords identify candidates, not ownership: read each complete skill before deciding where it belongs.
- For a multi-repository project, map each procedure to where it is used. App/API, runner/BPF, and profiler/parser workflows may belong in different repositories. Cross-repository procedures need an explicit scope decision.
- Inspect existing `.agents/skills/`, name collisions, scanner support, and ignore rules before copying. Preserve the whole directory, including references, scripts, licenses, and attribution. Never overwrite an existing skill silently.
- Back up the original and verify copied file contents. Update references and registrations before retiring any global entry.

## Git ignore rules

Use `git check-ignore -v --no-index -- .agents/skills/<name>/SKILL.md` to identify the matching rule. Exit 1 means no match, not an error to suppress indiscriminately; errors must remain visible. An explicit negated rule can appear in verbose output, so inspect the pattern as well as the status. Global ignore files may exclude `.agents` even when the repository does not.

When local policy permits tracking skills but no other agent artifacts, this pattern can reopen the parent and only the skills subtree:

```gitignore
!.agents/
.agents/*
!.agents/skills/
!.agents/skills/**
```

Replace or order conflicting repository rules deliberately; do not append blindly after assuming every repository has the same global ignore. Verify a real skill path is addable and unrelated `.agents` artifacts remain ignored. Not ignored does not mean tracked.

## Cut over

1. Prove discovery and resource retrieval from a fresh session inside the target repository, resolving to the copied file rather than a same-named global source.
2. Verify the scoped behavior outside that repository. A still-present global original masks this check; retire it only after in-repo discovery succeeds and a recoverable copy exists, then repeat the outside-repo check.
3. Remove the original through the supported managed-skill API. For ordinary writable source directories, use the repository's reversible deletion convention.
4. Preserve other stashes, index changes, and unrelated work. Stage or commit only when requested; heavy hooks are not permission to bypass them.

Report exactly which skills changed scope and any unresolved discovery or deployment boundary. Do not claim success from absence of a directory-name prefix alone.
