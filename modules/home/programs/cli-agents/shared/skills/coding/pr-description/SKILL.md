---
name: pr-description
description: "Use when writing or updating a pull request title or description, including after rebases, new commits or scope changes."
---

# PR description

Keep it compact. A long description doesn't get read. Include only what the reviewer needs and can't get from the diff.

## Content

- Open with a one-line `**TLDR:**`: the problem and the fix, in plain terms, with the main caveat (e.g. platform scope) in parentheses. It replaces a separate summary line; don't state the same thing twice.
- Then short bullets: each change with its measured effect. Explain a mechanism only when the reviewer needs it to judge whether the change is correct.
- Call out what needs care: behavior changes, risks, dependencies on unmerged work.
- For visible UI changes, include screenshots in the PR description. Use before/after images when they help reviewers compare the result.
- Add other evidence only when it proves something: before/after numbers, a link to the failing run, issue or dependent PR. Link inline where it's relevant.
- Report only numbers measured on the final code, and name the input. Leave out estimates, superseded figures and anything CI already shows.
- End with the issue reference, if there is one.

## Length

- Keep prose to a minimum. Aim for about 10 bullets and 150 words, excluding links and code. Go over only for a genuinely multi-part PR.
- A single change gets flat bullets. Several independent changes get a short bold label per group.
- Cut any sentence the reviewer wouldn't miss.

## Updating

When the PR changes (rebase, new commits, scope change), rewrite the body so it matches the current diff. Remove stale numbers, steps and claims. Don't add a revision log.

## Example

```markdown
**TLDR:** Large uploads pushed log ingestion past the worker's memory limit. The parser now streams records and the indexer batches writes.

**Parser**
- Stream records instead of loading the whole file.
- 2 GB upload: peak RSS 6.1 → 0.4 GiB, same output.

**Indexer**
- Batch writes per 10k records instead of per record.
- Same upload: 340 s → 95 s.

**Review notes**
- Records with duplicate ids now keep the first one instead of the last (changes one snapshot).
- Depends on example/storage#42, which is not merged yet.

Closes #123
```
