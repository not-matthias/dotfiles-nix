# Parallelism

- Use subagents aggressively whenever work splits into independent tracks.
- Use subagents by default for independent workstreams:
  - multiple failing tests
  - multiple PR comments
  - parallel research
  - large doc or wiki generation
  - separate writer/reviewer tasks
- Do not serialize work that can be parallelized safely.

# Style

- Write simply. Avoid AI-slop language – no flowery adjectives,
  unnecessary adverbs, or overly formal phrasing.
- Use en dashes (–) not em dashes (—).

# Code style

- Prefer simple code, early returns, and minimal diffs.
- Prefer deletion over extra abstraction when safe.
- If the implementation feels overcomplicated, simplify it before finalizing.

IMPORTANT: Try to preserve the original code and the logic of the original code as much as possible
