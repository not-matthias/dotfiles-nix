---
description: Change OMP settings in dotfiles-nix's source config rather than through cfg:// writes
condition: '^'
scope:
  - 'tool:write(cfg://**)'
interruptMode: always
---

Do not change OMP settings through `cfg://`, including session overrides and
persisted `/save` writes. Do not retry the change through `omp config set` or by
editing the generated `~/.omp/agent/config.yml`.

Edit `modules/home/programs/cli-agents/oh-my-pi/config.yml` in dotfiles-nix instead.
Resolve the repository with zoxide. Keep unrelated settings unchanged, validate
the YAML, and distinguish source changes from activation. Do not activate or
rebuild unless the user asks. Reading `cfg://` to inspect effective settings is
allowed.
