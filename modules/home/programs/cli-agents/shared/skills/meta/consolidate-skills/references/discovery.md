# Effective Skill Discovery

## Compare authored, installed, and exposed inventories

These are different sets. Resolve symlinks and parse YAML frontmatter rather than assuming a directory name is the runtime name. Record the selected file's real path when duplicate names exist.

- In OMP, a deliberately missing `skill://` read reports registered names. Hidden skills can be registered without appearing in the startup prompt. Avoid dumping the full list repeatedly.
- Read effective skill settings (`omp config list`), including `customDirectories`, source toggles, ignored/included skills, and disabled extensions. Do not launch an interactive agent just to list files, or assume an `omp skills list` command exists.
- Compare complete source inventories with registered names and exposed descriptions. A repository count alone is not a startup-context measurement.

## Diagnose a missing entry

1. Check whether the directory is tracked and included in the evaluated flake source. An untracked directory is absent from ordinary Git-backed flake evaluation even though it exists locally. `git status --porcelain -- <skill-dir>` distinguishes this from missing discovery wiring. Tracking is not deployment: an updated store-backed source also requires activation.
2. Inspect `disable-model-invocation: true` or `hide: true`. A direct `skill://<name>` read distinguishes a hidden entry from a missing one.
3. Match disabled entries against the frontmatter name, not directory basename. For example, a `mac-mini/` directory may declare `mac-mini-copy`, making `skill:mac-mini-copy` the relevant disabled entry.
4. Check effective source toggles, ignored/include filters, and program gating. An optional program's skills should be enabled only with that program.
5. Check the actual live path, scanner depth, and required metadata. OMP custom-directory scanning requires a description; a skill accepted by another provider can disappear there.

## Dotfiles-nix layout

Inspect `modules/home/programs/cli-agents/shared/skills.nix` and its consumers before changing wiring. The shared tree is categorized, while its flat farm exposes one absolute symlink per skill directory:

```text
installed-root/<skill> -> store-source/<category>/<skill>
```

The module recursively finds directories containing `SKILL.md`, adds program-owned skills, and deliberately lets duplicate basenames fail rather than shadow silently. Absolute targets survive Home Manager's file-tree copying. Do not copy category directories into a non-recursive scanner root and expect discovery.

OMP's module derives `skills.customDirectories` from `home.homeDirectory`, pointing at `~/.omp/agent/skills`. Do not restore historical lists of nested parent paths without checking current source.

Store-backed symlinks do not follow working-tree edits. Build inspection can prove future Home Manager wiring, but does not update the installed library. Never edit the store or replace Home Manager-owned links imperatively. Keep originals until the replacement is installed and resolves to the expected content; request deployment authorization separately when needed.

## Wrong content under the right name

OMP's documented discovery model uses provider priorities and then custom directories. Historically the order was native (100), OMP plugins (90), Claude (80), Claude plugins/agents/Codex (70), OpenCode (55), GitHub (30), managed (5). Custom directories are a second pass overriding same-named provider entries, with the first matching custom directory winning. Identical real paths are deduplicated.

Check the installed runtime's behavior before relying on those numeric priorities. In particular, removing custom-directory configuration can let unmanaged Claude content shadow shared skills. Inspect configured roots for stale backup directories and duplicate frontmatter names. Compare resolved content, not merely counts, before retiring an original.
