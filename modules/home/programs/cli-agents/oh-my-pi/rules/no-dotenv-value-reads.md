---
description: Read .env files through env-redact so secret values stay out of the transcript in shell commands
condition:
  - '(?:^|[;&|()\n])\s*(?:sudo\s+)?(?:(?:cat|bat|less|more|head|tail|source|xxd|hexyl|od|strings|jq)\b|\.(?=\s))[^;&|\n]*(?:^|[\s"''/])\.env(?!\.(?:example|sample|template|dist|tpl)\b)(?:\.[A-Za-z0-9_-]+)?(?=$|[\s"''])'
  - '(?:^|[;&|()\n])\s*(?:sudo\s+)?(?:rg|grep|egrep|fgrep|ripgrep|awk|sed|cut|tr|perl|python3?)\b[^;&|\n]*(?:^|[\s"''/])\.env(?!\.(?:example|sample|template|dist|tpl)\b)(?:\.[A-Za-z0-9_-]+)?(?=$|[\s"''])'
scope:
  - 'tool:bash'
interruptMode: always
---

Do not print raw `.env` values. The command output lands in the session
transcript and is sent to the model provider, so a database URL or API key read
this way counts as leaked and has to be rotated.

Use `env-redact <file>` instead. It keeps keys, comments and quoting, masks the
values, and shows only the first few characters (`-n 0` hides them entirely) —
enough to tell which database or account a file points at.

If a real value is genuinely required, ask the user for it. Never echo a secret
into chat, a file, a commit, or a command line; pass it via the process
environment or a secret manager that does not expand it into the command.

Template files (`.env.example`, `.env.sample`, `.env.template`), `.envrc`, and
creating or editing a `.env` are unaffected.
