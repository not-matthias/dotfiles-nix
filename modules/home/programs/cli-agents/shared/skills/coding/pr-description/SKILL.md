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
- For visible UI changes, include screenshots for static results or a short video for interactions, transitions and multi-step flows. Use before/after evidence only when it helps reviewers compare the result.
- Add other evidence only when it proves something: before/after numbers, a link to the failing run, issue or dependent PR. Link inline where it's relevant.
- Report only numbers measured on the final code, and name the input. Leave out estimates, superseded figures and anything CI already shows.
- End with the issue reference, if there is one.

## Recording demos

Choose the recorder for the changed surface:

1. **Browser (default for web UI):** Reuse the project's Playwright automation. Enable [`recordVideo`](https://playwright.dev/docs/videos) before creating the page, set explicit viewport and video sizes, and await `context.close()` to flush the file. With a supported [Playwright CLI](https://github.com/microsoft/playwright-cli/blob/main/skills/playwright-cli/references/video-recording.md), run `playwright-cli video-start .agents/demo.webm --cursor`, perform the flow, then run `playwright-cli video-stop`. Check installed command support first.
2. **Desktop/native UI:** Use OBS with a window capture; on [Niri, use the PipeWire/portal capture source](https://niri-wm.github.io/niri/Screencasting.html). Capture the desktop only when the behavior crosses windows.
3. **CLI/TUI:** Use [VHS](https://github.com/charmbracelet/vhs) for repeatable terminal demos: write a `.tape` with `Output demo.mp4`, the real commands and readable pauses, then run `vhs demo.tape`.

- Record one real scenario on the final code. Aim for 10–30 seconds, readable text and a clear initial state, action and result. Pause briefly on the result; omit setup and idle time.
- Use test data, hide notifications and keep credentials and private content out of the capture. Do not simulate the changed behavior with overlays or edited frames.
- Watch the finished clip before attaching it. Check legibility, pacing, the claimed result and accidental disclosure.
- Prefer H.264 MP4 for browser compatibility; WebM is also accepted. Keep videos under 10 MB to fit free-plan uploads (paid plans allow up to 100 MB). See [GitHub's media limits](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files).
- [Attach to GitHub](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli), rather than committing the video: use `--attach` on PR create/edit when supported, or drag it into the PR editor. Keep the video reference alone in its paragraph so it renders as a player.

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
