---
description: Inject 1Password secrets with op run instead of substituting op read into a command
condition:
  - '[$`]\(?\s*(?:sudo\s+)?op\s+(?:read|item\s+get|inject)\b'
  - '(?:^|[;&|()\n])\s*(?:sudo\s+)?op\s+read\b(?![^;&|\n]*>)'
scope:
  - 'tool:bash'
interruptMode: always
---

Do not substitute a secret into a command line, as in
`psql "$(op read 'op://vault/item/field')"`. The shell expands it before the
command runs, and the expanded form is what gets recorded — so the credential
ends up in the transcript and in process arguments, and has to be rotated.

Use `op run` instead, which passes the secret through the environment:

```sh
op run --env-file=.env -- psql "$DATABASE_URL"   # .env holds op:// references
op run -- sh -c 'psql "$DATABASE_URL"'           # single-quoted: no expansion here
```

The same applies to any secret source: keep the value in the environment or a
file the command reads itself, never in an expanded argument or on stdout. A
bare `op read` prints the secret into the transcript; redirect it to a file
(`op read 'op://…' > .env`) when a file is what you actually need. If you only
need to know which account or database a reference points at, read the `op://`
reference or run `env-redact` — do not resolve the value.
