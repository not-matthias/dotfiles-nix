---
name: ida-plugin-development
description: Develop Python plugins for IDA Pro 9.x, including lifecycle, Qt6 UI, actions, menus, hooks, settings, logging, and persisted plugin state. Use when creating or maintaining an IDA plugin.
license: MIT
---

<!-- Source: https://github.com/HexRaysSA/claude-marketplace/tree/main/plugins/ida-plugin-development/skills/ida-plugin-development -->

# Developing IDA Pro plugins

Target IDA Pro 9.x and keep plugin infrastructure separate from binary-analysis logic.

- Prefer `ida-domain` for analysis logic.
- Use IDA's documented Qt6 APIs for presentation.
- Use `ida-settings` for persistent configuration.
- Use Python's standard `logging` module for diagnostics.

## Lifecycle and UI

Register actions, menus, hotkeys, hooks, and widgets during plugin initialization. Unregister hooks and dispose of UI resources during shutdown. Keep the entry point small and delegate analysis and UI behavior to focused modules.

Scope widget lookups to stable prefixes rather than assuming a particular foreground tab. Handle current address and selection changes through supported hooks. Test both GUI and background behavior when the plugin supports both.

For custom views, prefer IDA's existing viewer and chooser infrastructure before building a new Qt surface. Keep long-running analysis off the UI thread and report failures through logging or an explicit UI message.

## State and communication

Use supported IDC functions or netnodes for deliberate cross-plugin communication and persisted state. Validate stored state when loading it, and make shutdown safe when initialization only partially completed.

Keep analysis writes explicit. Read the current name, comment, type, or address before changing it, and verify the result after the operation. Never assume that a plugin's selected widget or database is the intended target.

## Development checklist

- Confirm the plugin loads in a clean IDA user directory.
- Exercise initialization and shutdown more than once.
- Verify actions, menus, hotkeys, and hooks in the intended UI context.
- Test missing settings, stale persisted state, and an unavailable target address.
- Keep the plugin root self-contained for HCLI packaging; see `package-ida-plugin`.
