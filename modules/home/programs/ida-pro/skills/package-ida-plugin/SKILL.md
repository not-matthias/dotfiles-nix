---
name: package-ida-plugin
description: Package Python or native IDA Pro plugins for HCLI and plugins.hex-rays.com. Use when creating ida-plugin.json, linting an archive, or preparing a GitHub Release.
license: MIT
---

<!-- Source: https://github.com/HexRaysSA/claude-marketplace/tree/main/plugins/ida-plugin-development/skills/package-ida-plugin -->

# Packaging IDA Pro plugins

The directory containing `ida-plugin.json` is the plugin root. Only that directory and its children are included in the installed plugin.

## Before packaging

Verify that:

- `entryPoint` and every imported module are inside the plugin root.
- Runtime assets and the plugin README are inside the plugin root.
- The manifest has `IDAMetadataDescriptorVersion: 1`.
- `plugin.name` uses valid ASCII letters, digits, underscores, or hyphens.
- `plugin.version` is semantic and has no leading `v`.
- `plugin.urls.repository` points to the source repository.
- An author or maintainer includes an email address.
- Python dependencies are declared in `pythonDependencies` or PEP 723 inline metadata.
- Native plugins provide the required platform archives and entry points.

Do not reference files above the manifest directory. In a monorepo, place the manifest beside the actual plugin code rather than at the repository root.

## Lint and install

Build the archive with the plugin root as its top-level directory, then lint the archive before publishing:

```bash
uv run --with=ida-hcli hcli plugin lint ./plugin.zip
uv run --with=ida-hcli hcli plugin install ./plugin.zip
```

Use a clean IDA user directory for the installation check. Do not publish a release merely to test manifest syntax.

## Publishing

Publish a versioned archive through a GitHub Release. Confirm that the plugin is indexed and can be installed from the published archive. For updates, increment the manifest version and verify the archive contains the new entry point, assets, and dependencies.
