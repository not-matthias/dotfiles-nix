---
name: consolidate-skills
description: Audit, deduplicate, and consolidate first-party agent skills to reduce context size; diagnose discovery or relocate skills when explicitly requested.
---

# Consolidate Skills

Reduce startup context without losing useful procedures. Audit and propose by default; apply only approved changes. Imported skills remain unchanged, including their attribution and update path.

## Choose the procedure

- For merging, generalizing, or retiring skills, read [Merge review](references/merge-review.md).
- For missing skills, wrong versions, hidden entries, or dotfiles-nix wiring, read [Discovery](references/discovery.md).
- Only when project-local relocation is requested, read [Relocation](references/relocation.md).

## Inventory and propose

1. Resolve configured roots and symlink targets. Record names, descriptions, ownership, resources, and inbound references; do not count installed copies as separately authored skills.
2. Read complete candidate bodies and relevant resources. Compare intent, prerequisites, procedure, and safety boundaries, not just names. Missing usage data means unknown use. A locally absent tool may still be useful remotely or on demand.
3. Prefer a managed survivor or a new managed root. Keep project-specific skills globally available unless the user asks to change their scope. Suggest suitable existing dotfiles-nix targets separately, naming exact paths and references; do not move new consolidations there by default.
4. Present each family with sources, destination, retained facts, contradictions, proposed deletions, and conditional reference routes. Keep different intents or permission boundaries separate.
5. Measure exposed name/description bytes separately from root-plus-required-reference bytes. Use a tokenizer only if available; never label byte estimates as tokens. Directory grouping alone saves no startup context.

Report the savings and selection tradeoff, including rare cases made harder to find. Include a **Suggested dotfiles-nix merges** section when applicable. Stop until mutations are approved.

## Apply and verify

- Back up complete source directories and preserve unrelated work. Use the supported managed-skill API; never edit generated/store-backed copies or restricted user-authored roots.
- Keep roots short. Put variant details in references linked directly with reading conditions; retain exact flags, errors, ordering, and restoration requirements.
- Update inbound links and registrations. Verify frontmatter, unique names, resources, attribution, and effective discovery before retiring originals. A repository edit is not an installed update.
- Check ordinary, rare-gotcha, and adjacent-unrelated prompts. Distinguish a routing simulation from actual runtime discovery; do not execute dangerous examples as a documentation test.
- Report measured startup and representative activation deltas, changed paths, and blocked cutovers. Do not commit, push, rebuild, or activate configuration unless requested.

<!-- Sources: https://agentskills.io/specification ; https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices ; https://agentskills.io/skill-creation/evaluating-skills -->
