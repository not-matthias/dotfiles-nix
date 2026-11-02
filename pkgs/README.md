# Custom Packages

## Development

Build with:
```
nix build -f foo.nix
```

Run with:
```
nix run -f foo.nix
```

## Binary packages

- 2026-10-22: Feishin, HushMic, and Navidrome use pinned upstream Linux release binaries. Navidrome retains the module's plugin selection and ffmpeg wrapper.
- Vicinae uses its upstream Nix build through `vicinae.cachix.org`. The cache and signing key are configured for both flake builds and the Nix daemon.
- BlueZ uses nixpkgs-unstable's cached 5.87 build, which includes the A2DP sink-priority fix.
- ActivityWatch's Rust server and sync client use the official 0.14.1 bundle on x86_64 Linux, which includes the heartbeat-ID fix. Other architectures retain the patched source package.
- Handy and tldraw offline use AppImages. The AppImage extractor runs with shell error checking so a failed extraction cannot be registered as a successful, incomplete store output.
- Choosr and Steelix retain source builds because their selected packages include local fixes. Replacing them with unpatched binaries would drop those fixes. Feishin also retains source builds outside x86_64 Linux: the upstream ARM64 release includes an x86_64 native module.
- 2026-10-26: slackcli uses pinned upstream Linux release binaries with patched ELF interpreter, wrapped with xclip and procps in PATH and SLACKCLI_NO_UPDATE_NOTIFIER=1.

## Tern

- 2026-10-05: Include WebKitGTK 4.1 and GLib's TLS modules for embedded HTTPS pages.
- Launch the package's `bin/tern` wrapper; the binary in `libexec/tern` does not set up TLS modules.
- 2026-10-19: Link the local `multiplexer` plugin when Tern is enabled. The first load applies the Herdr profile and personal shortcuts.
- The command palette's **Multiplexer** group offers **Use herdr/tmux/zellij shortcuts** and **Restore shortcuts from before Multiplexer**. Personal direct shortcuts remain active in every profile. Restore before disabling or unlinking the plugin; later manual edits are preserved.
- Customize `tern-plugins/multiplexer/profiles.luau`: `styles` defines profile bindings, and `personal` intentionally overrides them. Reapply the profile after editing.

| Herdr shortcut | Action |
| --- | --- |
| `Ctrl+B`, `H/J/K/L`; `Ctrl+Alt+H/J/K/L` | Focus left/down/up/right |
| `Ctrl+B`, `P/N`; `Ctrl+Alt+[/]`; `Ctrl+Shift+Tab` / `Ctrl+Tab` | Previous/next tab |
| `Ctrl+B`, `C`; `Ctrl+Alt+C` | New tab |
| `Ctrl+B`, `V`; `Ctrl+Alt+D` | Split right |
| `Ctrl+B`, `-`; `Ctrl+Alt+Shift+D` | Split down |
| `Ctrl+B`, `Z`; `Ctrl+Alt+Z` | Toggle zoom |
| `Ctrl+B`, `B`; `Ctrl+Alt+B` | Toggle sidebar |
| `Ctrl+Alt+Tab` | Focus last pane |
| `Ctrl+B`, `.` / `,` | Next/previous agent |
| `Ctrl+B`, `Shift+1…9` | Focus agent by tab order, then pane ID |
| `Ctrl+B`, `Shift+R` | Rename the focused agent's plugin label |
| `Ctrl+B`, `W` | Choose an agent |
| `Ctrl+B`, `Ctrl+B` | Send Ctrl+B to the program |

- Agent shortcuts stay within the current Tern session and skip parked panes. Labels appear in the agent picker and, when enabled, the status bar. They do not rename the Tern workspace, tab, or underlying agent conversation.
- The tmux profile uses `Ctrl+B` followed by `%` / `"` for splits, arrows for focus, `O` for the next pane, `;` for the last pane, `C/P/N` for tabs, `1…9` for tab selection, `Z` for zoom, `X` / `&` for guarded pane/tab close, `,` for tab rename, `[` for scrollback, and Space to equalize.
- The Zellij-style profile uses one-shot sequences, not persistent modes: `Ctrl+P` then `H/J/K/L`, `R/D`, `N`, `X`, `F`, or `W` for pane focus, splits, a right split, close, zoom, or equalize; `Ctrl+T` then `N/H/L/X/R/1…9` for tabs; `Ctrl+N` then `H/J/K/L` for resizing. `Alt+H/J/K/L` focuses panes directly.

## Choosr

- 2026-10-08: Launch browsers through `gio launch` using their desktop files so quoted profile arguments such as `Profile 1` remain intact.
