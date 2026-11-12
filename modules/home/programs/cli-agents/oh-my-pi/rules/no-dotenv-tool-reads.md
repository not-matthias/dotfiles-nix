---
description: Do not open .env files with the read tool; use env-redact instead
condition: '\.env(?![A-Za-z0-9_-])(?!\.(?:example|sample|template|dist|tpl)\b)(?:\.[A-Za-z0-9_-]+)?'
scope:
  - 'tool:read(**/.env*)'
interruptMode: always
---

Do not read a `.env` file into the transcript. Its contents are sent to the
model provider, so every value in it counts as leaked and has to be rotated.

Run `env-redact <file>` instead: it keeps keys, comments and quoting while
masking the values, which is enough to tell which database or account the file
points at. Use `-n 0` to hide the value prefixes entirely.

If a real value is genuinely required, ask the user for it instead of reading
the file, and never echo it into chat, a file, a commit, or a command line.

Template files (`.env.example`, `.env.sample`, `.env.template`) are unaffected.
