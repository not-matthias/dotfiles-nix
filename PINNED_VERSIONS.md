# Pinned Versions

Inventory recorded on 2026-10-08. Includes explicit definitions, which are not necessarily enabled on every host. Excludes automatic transitive lockfile dependencies, ordinary nixpkgs versions, and locally authored plugin metadata. Commit revisions below are abbreviated to 12 characters; source files contain the full revisions.

## Custom software

Sources are `pkgs/<name>.nix` unless noted.

| Software | Version |
|---|---|
| amp-cli | `0.0.1789566678-g555089` |
| antigravity | `2.5.5`; installer build `4923483625488384` |
| aw-watcher-media-player | `1.1.4` |
| Binary Ninja | `6.0.10601` (`pkgs/binary-ninja.nix`) |
| binja-codemode-mcp | `0.1.3` |
| binja-headless | `0.1.0-unstable-2025-02-13` |
| binja-wasm | `0.1.1` |
| choosr | `1.0.0-unstable-2026-09-16` |
| Detect It Easy | `3.21` (`pkgs/detect-it-easy.nix`) |
| disktree | `0.11.0` |
| feishin | `1.8.0` |
| ghidra-cli | `0.2.2` |
| greptile | `3.6.1` |
| handy | `0.9.8` |
| harbor | `0.5.10` |
| helix-file-watcher | `unstable-2026-08-30`; commit `8cd0726da47b` |
| herdr-gpui | `20261007.3` |
| hermes-agent | `0.3.0`; commit `6ebb816e5611` |
| hushmic | `0.8.1` |
| jcode | `0.84.0` |
| linear-cli | `3.0.0` |
| lmstudio | `0.4.24-1` |
| lobe-chat | `1.114.0` |
| mcporter | `0.13.13` |
| msty | `1.0` (derivation label; URL has no release version) |
| oh-my-pi | `18.10.3` |
| openclaw desktop | `2026.9.5` (`pkgs/openclaw.nix`) |
| oracle | `0.21.4` |
| paper-mono | `1.000` |
| paperclip | `2026.626.0` |
| Pi coding agent | `1.1.0` (`pkgs/pi-mono/default.nix`) |
| Pi session manager | `0.4.9` (`pkgs/pi-session-manager.nix`) |
| plannotator | `0.28.17` |
| qmd | `2.8.3` |
| radius2 | `1.2.0` |
| rtk | `0.49.0` |
| slk | `0.16.0` |
| solidtime desktop | `0.3.2` (`pkgs/solidtime.nix`) |
| soulsync | `3.4.2` |
| terminal-browser | `0.8.1` |
| tern | `0.6.2` |
| tldraw-offline | `1.21.0` |
| vmprotect | `demo` (no numeric release identified) |

## IDA packages and plugins

Sources are `pkgs/ida-pro/<name>.nix`.

| Package | Version |
|---|---|
| ida-pro | `9.4` |
| ida-sdk-source | `9.4`; tag `v9.4.0-sdk.1` |
| bindiff | `release-20260302-1` |
| binsync | `5.11.2` |
| headless-ida | `0.6.8` |
| ida-bitopt | `1.0.1` |
| ida-codemode | `0.6.1` |
| ida-d810 | `unstable-2026-08-30`; commit `87fe12ca9cfb` |
| ida-domain | `0.5.1` |
| ida-guides | `1.3.0` (source URL uses `main`, content fixed by hash) |
| ida-hrtng | `unstable-2026-08-30`; commit `eb6b9c203a5f` |
| ida-lifter | `2.2.0` |
| ida-mcp-rs | `9.3.1`; commit `216a67786a7b` |
| ida-mcp | `0.8.1`; commit `a36a51c9d68d` |
| ida-nexus | `0.9.1`; commit `abac0b389fe2` |
| ida-sigmaker | `v1.6.0` |
| ida-structor | `1.0.0`; commit `46d744d13a4e` |
| ida-theme-explorer | `1.0.3` |
| ida-wakatime | `1.1` |
| idasql | `0.0.18.1` |

### Bundled dependencies

| Package | Version | Source |
|---|---|---|
| fal-client | `0.13.1` | `pkgs/hermes-agent.nix` |
| honcho-ai | `2.0.1` | `pkgs/hermes-agent.nix` |
| firecrawl-py | `4.19.0` | `pkgs/hermes-agent.nix` |
| agent-client-protocol | `0.8.1` | `pkgs/hermes-agent.nix` |
| pycparser | `2.23` | `pkgs/ida-pro/binsync.nix` |
| libbs | `3.3.3` | `pkgs/ida-pro/binsync.nix` |
| idapro | `0.0.10` | `pkgs/ida-pro/ida-domain.nix`, `ida-codemode.nix` |
| zeromcp | `1.9.0` | `pkgs/ida-pro/ida-nexus.nix` |

## Pi packages

Sources are `pkgs/pi-mono/packages/<name>.nix` unless noted.

| Package | Version |
|---|---|
| pi-agentic-compaction | `0.3.1` |
| pi-anthropic-oauth | `0.3.1` |
| pi-diff | `0.9.2` |
| pi-goal | `0.0.2-unstable-2026-05-28` |
| pi-codex-conversion | `3.0.47` (`pkgs/pi-mono/extensions/pi-codex-conversion.nix`; maintained `@howaboua` package, with Codex Code Mode host `0.145.0`) |
| pi-openai-server-compaction | `0.1.0` |
| pi-pretty | `0.6.31` |
| pi-queue-picker | `1.0.5` |
| pi-web-access | `0.37.0` |
| tintinweb-pi-subagents | `0.19.0` |
| pi-token-usage | `0.4.0` (commented-out integration; `pkgs/pi-mono/extensions/pi-token-usage.nix`) |

### Pi extensions pinned by commit

Sources are `pkgs/pi-mono/extensions/<name>.nix`.

| Extension | Commit |
|---|---|
| askuserquestion | `e58609c9e9c8` |
| context-guard | `e4e047a5a203` |
| fzf | `dd0ef2eed872` |
| guardrails | `4eeb71c1c317` |
| mermaid | `34cab3ae7944` |
| nupi | `4845cb4a32f2` |
| pi-better-messages-cache | `7798b5f49366` |
| pi-claude-bridge | `b2e7255ece0b` |
| pi-codex-fast | `d83b218459f0` |
| pi-codex-goal | `31a1d4555304` |
| pi-curated-themes | `ac8e0c8e890a` |
| pi-diff-review | `57622138f5b0` |
| pi-dynamic-workflows | `31b2aca0f1cb` |
| pi-fff | `bb35f3659f30` |
| pi-memory | `79d019bfc687` |
| pi-mouse | `fc3c4be04bca` |
| pi-pane | `03ca432dea29` |
| pi-ptc | `b567c8902d75` |
| pi-subdir-context | `c63f4876ba39` |
| pi-tool-display | `91cef7580078` |
| pi-verbosity-control | `5b4573bc25f1` |
| pi-workflow-kit | `2d399948edfa` |
| processes | `434fa0a860b1` |
| rtk-rewrite | `5c4fcc614c2c` |
| santychuy-mermaid | `0a0692fffea3` |
| sub-bar | `65deb56853b9` |
| subagents | `0c33ec7cb26e` |
| tasks | `29180d72498b` |
| toolchain | `b1608a5ef9e68` |
| web-providers (upstream webfox) | `2fcc7d99d8e0` |

### Pi 1.1 compatibility

- Updated on 2026-10-08. Existing enabled and disabled selections are preserved.
- Extensions retain runtime-loaded TypeScript helpers. Compiled manifests declare only extension entrypoints; TypeBox is supplied by Pi.
- Web access compiles its TypeScript entrypoint so the local GitHub extraction patch remains effective. Its MCP CLI is not an extension entrypoint.
- The archived better-messages-cache integration stays disabled. OpenAI server compaction also stays disabled because its declared Pi peer range excludes Pi 1.
- Goal, RTK rewrite, and santychuy Mermaid use the latest source revisions that retain their selected extraction paths. Memory uses the flattened upstream layout.
- Claude bridge includes the Claude Agent SDK's required Anthropic SDK peer in its dependency lock.

## Other software and plugins

| Software | Version or commit | Source |
|---|---|---|
| Herdr | `0.9.3` | `modules/home/programs/cli-agents/herdr/default.nix` |
| OneLeet | `2.2.8` | `modules/system/programs/oneleet.nix` |
| BleachHack | `1.2.6` | `modules/home/programs/minecraft.nix` |
| VS Code JetBrains icon theme | `2.40.0` | `modules/home/programs/vscode/default.nix` |
| Caddy DuckDNS plugin | `v0.5.0` | `modules/system/services/caddy.nix` |
| steel-pty | `0.1.0-unstable-2026-08-28`; commit `4d41b6988107` | `modules/home/programs/helix/default.nix`, `flake.nix` |
| Herdr collie | `1.6.0`; commit `2e3df8aa32e5` | Herdr module, `hosts/pc/default.nix` |
| Herdr worktrunk | Commit `8ceca541de8f` (source comment says `0.1.0`, but revision is newer than tag `v0.7.0`) | Herdr module, `hosts/pc/default.nix` |
| Herdr auto-title | `0.4.0`; commit `0f0026b0897f` | `hosts/pc/default.nix` |
| Herdr annotate | `0.3.0`; commit `46cbf5dab174` | `hosts/pc/default.nix` |
| Herdr resurrect | `0.2.0`; commit `5afa6755d4f3` | `hosts/pc/default.nix` |
| Mutter override (disabled) | Commit `663f19bc02c1` | `modules/overlays/gnome.nix` |
| Bluetooth patch (not a BlueZ version pin) | Commit `066a164a524e` | `modules/system/hardware/bluetooth.nix` |

## Containers

Sources are `modules/system/services/<service>.nix` unless noted. Version tags select releases but can be moved upstream; only digest pins identify immutable image content.

| Container | Tag |
|---|---|
| browserless/chrome | `1.61.1-chrome-stable` (`change-detection.nix`) |
| changedetection.io | `0.55.8` (`change-detection.nix`) |
| Kaneo | `2.22.0` |
| Kokoro FastAPI CPU/GPU | `v0.8.1` |
| Kokoro UI (commented out) | `v0.1.0` |
| Lobe Chat database | `1.143.3` |
| Logto | `1.43.0` |
| Maloja | `3.2.6` |
| Memos | `0.30.0` |
| multi-scrobbler | `0.16.5` |
| NocoDB | `2026.08.1` |
| Postiz | `v2.23.0` |
| Postiz PostgreSQL | `17.11-alpine` |
| Solidtime | `0.20.0` |
| Stump | `0.1.6` |
| Sure web/worker | `0.7.4` |
| Sure PostgreSQL | `16.15` |
| Traggo | `0.8.3` |
| Twenty server/worker | `v2.37.0` |
| Twenty PostgreSQL | `16.15-alpine` |
| WatchYourLAN | `2.1.4` |
| Ziit | `v1.1.3` |

OpenClaw uses digest `sha256:0a5ff5e682e62afa19149df126aa50063bf65ef885b5c94713ce32dc0eb12e15` in `modules/system/programs/openclaw.nix`.

## Direct flake release and commit pins

Source: `flake.nix`. Resolved revisions for all flake inputs are recorded separately in `flake.lock`.

| Input | Explicit pin |
|---|---|
| devenv | `v2.4.0` |
| hunk | `v0.23.0` |
| steel-pty | Commit `4d41b6988107` |
| microscopehx | Commit `7fe4e60f0c4f` |

## Related selections that are not exact release pins

- Release/channel selections: nixpkgs `26.05-chilled/0.1`, Home Manager and Stylix `release-26.05`, Nixvim `nixos-26.05`, and nixpkgs `nixos-unstable`.
- Major-version selections: Docker 29, Garage 2, PostgreSQL 16, and Taskwarrior 3. Minor versions come from nixpkgs.
- Octo-fiesta uses floating container tag `dev` in `modules/system/services/octo-fiesta.nix`.
- The disabled Discord overlay uses a floating `latest` tarball URL with a fixed content hash in `modules/overlays/discord.nix`; no release version is identified.
- Floating source selectors in `flake.nix`: nixos-hardware `master`, nix-webapps `tlater/idiomatic-flake`, hera `main`, determinate `*`, and Oh My Pi `perf/startup-optimizations`.
- The Google fonts overlay uses a `master` archive with a fixed content hash in `hosts/default.nix`.
- Hushmic's DPDFNet model downloads use Hugging Face `main` URLs with fixed content hashes.
- `permittedInsecurePackages` entries for Electron and pnpm allow versions; they do not select or pin packages.
- OpenCode auth plugins use `opencode-antigravity-auth@latest` and `opencode-gemini-auth@latest` in `modules/home/programs/cli-agents/opencode/default.nix`.
- Helix inputs `vimhx`, `wakatimehx`, `zenmode`, `foresthx`, `notifyhx`, and `glyphhx` use default branches in `flake.nix`; their resolved commits are in `flake.lock`.

## Additional package source commit pins

These revisions supplement the version labels above.

| Source | Full revision |
|---|---|
| `pkgs/binja-codemode-mcp.nix` | `97651d17c15c38ee779d1c4dc354053df3931bf2` |
| `pkgs/binja-headless.nix` | `e6ab5adb2188efd27c3485fd014125c8b9a2648b` |
| `pkgs/choosr.nix` | `1e6b47774b8bd02d1f4135305fc5b7ac61e675a9` |
| `pkgs/ghidra-cli.nix` | `10019ba1f3b54c9edcca8ec644a30e16fb7b7c79` |
| `pkgs/helix-file-watcher.nix` | `8cd0726da47be4a1011c3246ff308c1dfefda9d1` |
| `pkgs/hermes-agent.nix` | `6ebb816e5611aaf1f3f7187ba8b10e985e899c75` |
| `pkgs/ida-pro/ida-bitopt.nix` | `b25b2adc36d9bf7449a3c64b3ab6661c558547d6` |
| `pkgs/ida-pro/ida-d810.nix` | `87fe12ca9cfbea5744c30546308898bf7199c073` |
| `pkgs/ida-pro/ida-hrtng.nix` | `eb6b9c203a5f3a84c90d982ebf8981683233f231` |
| `pkgs/ida-pro/ida-mcp-rs.nix` | `216a67786a7b7ca7d1b7c4808bce2a7a85393aa9` |
| `pkgs/ida-pro/ida-mcp.nix` | `a36a51c9d68d7e8822348e057b1e82c633f2b8dd` |
| `pkgs/ida-pro/ida-nexus.nix` | `abac0b389fe280e66f17f74a17708ee38dc0bb0a` |
| `pkgs/ida-pro/ida-structor.nix` | `46d744d13a4e631ad79385beaf410f0b842b0802` |
| `pkgs/mcporter.nix` | `e4cb002200e44460279d414b0d1dec597b978f06` |

## Pre-update upstream audit

Recorded on 2026-10-08 before the requested package updates, against upstream releases, registries, and source revisions. This historical snapshot corrects checker false positives caused by unstable version labels, renamed repositories, and mismatched dependency sources.

The “Current” columns below show the pins before updates, not the current repository state. The inventory above is authoritative for applied updates. Source and dependency hashes and local patches were refreshed for the requested packages.

### Software and bundled dependencies

| Package | Current | Available | Evidence / constraint |
|---|---|---|---|
| amp-cli | `0.0.1789566678-g555089` | `0.0.1791446565-g95411c` | [Official version manifest](https://static.ampcode.com/cli/cli-version.txt) |
| binja-codemode-mcp | `0.1.3` | `0.2.0` | [Release](https://github.com/akrutsinger/binja-codemode-mcp/releases/tag/0.2.0); bridge architecture changed |
| binja-wasm | `0.1.1` | `0.2.0` | [Release](https://github.com/chadhyatt/binja-wasm/releases/tag/0.2.0); built for Binary Ninja 6 |
| feishin | `1.8.0` | `1.17.0` | [Release](https://github.com/jeffvli/feishin/releases/tag/v1.17.0) |
| greptile | `3.5.4` | `3.6.1` | [npm](https://registry.npmjs.org/greptile) |
| handy | `0.9.6` | `0.9.8` | [Release](https://github.com/cjpais/Handy/releases/tag/v0.9.8) |
| harbor | `0.5.10` | `0.5.14` | [Release](https://github.com/av/harbor/releases/tag/v0.5.14) |
| hermes-agent | `0.3.0` | Release `v2026.9.24` | [Release](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.9.24); substantial dependency and bridge changes |
| fal-client | `0.13.1` | `1.0.3` | [PyPI](https://pypi.org/project/fal-client/1.0.3/); major upgrade |
| honcho-ai | `2.0.1` | `2.5.1` | [PyPI](https://pypi.org/project/honcho-ai/2.5.1/) |
| firecrawl-py | `4.19.0` | `4.49.3` | [PyPI](https://pypi.org/project/firecrawl-py/4.49.3/) |
| agent-client-protocol | `0.8.1` | `0.12.1` | [PyPI](https://pypi.org/project/agent-client-protocol/0.12.1/) |
| hushmic | `0.8.1` | `0.10.2` | [Release](https://github.com/Fovty/HushMic/releases/tag/v0.10.2) |
| jcode | `0.84.0` | `0.91.0` | [Release](https://github.com/1jehuang/jcode/releases/tag/v0.91.0) |
| linear-cli | `2.6.0` | `3.0.0` | [Release](https://github.com/schpet/linear-cli/releases/tag/v3.0.0); Rust rewrite and CLI changes |
| lmstudio | `0.4.24-1` | `0.4.25-1` | [Changelog](https://lmstudio.ai/changelog/lmstudio/lmstudio-v0.4.25); Linux AppImage available |
| lobe-chat desktop | `1.114.0` | `2.2.19` | [Release](https://github.com/lobehub/lobehub/releases/tag/v2.2.19); major upgrade and renamed AppImage |
| mcporter | `0.13.13` | `0.14.2` | [Release](https://github.com/openclaw/mcporter/releases/tag/v0.14.2) |
| oracle | `0.21.3` | `0.21.4` | [Release](https://github.com/steipete/oracle/releases/tag/v0.21.4); check local patches |
| paperclip | `2026.626.0` | `2026.1005.0` | [Release](https://github.com/paperclipai/paperclip/releases/tag/v2026.1005.0); database migrations |
| pi-session-manager | `0.4.9` | `0.8.9` | [Release](https://github.com/Dwsy/pi-session-manager/releases/tag/v0.8.9); tarball replaced by bare binary |
| plannotator | `0.28.5` | `0.28.8` | [Release](https://github.com/backnotprop/plannotator/releases/tag/v0.28.8) |
| rtk | `0.49.0` | `0.51.0` | [Release](https://github.com/rtk-ai/rtk/releases/tag/v0.51.0); script execution CLI changes |
| slk | `0.16.0` | `0.25.0` | [Release](https://github.com/gammons/slk/releases/tag/v0.25.0) |
| soulsync | `3.4.2` | `3.5.2` | [Release](https://github.com/Nezreka/SoulSync/releases/tag/3.5.2) |
| terminal-browser | `0.8.1` | `0.13.4` | [Release](https://github.com/zenbu-labs/terminal-browser/releases/tag/v0.13.4) |
| tldraw-offline | `1.19.0` | `1.21.0` | [Release](https://github.com/tldraw/tldraw-offline/releases/tag/v1.21.0) |
| OneLeet | `2.2.8` | `2.3.1` | [Linux installer](https://downloads.oneleet.com/agent/linux/Oneleet_2.3.1_amd64.deb); endpoint returned HTTP 200 |

### IDA ecosystem

| Package | Current | Available | Evidence / constraint |
|---|---|---|---|
| ida-pro | `9.4` | `9.5` | [Official announcement](https://hex-rays.com/blog/ida-9.5-three-new-decompilers); licensed installer and plugin compatibility checks required |
| bindiff | `release-20260302-1` | `release-20260716-1` | [Release](https://github.com/Lil-Ran/build-bindiff-for-ida-9/releases/tag/release-20260716-1); IDA 9.4 builds available |
| pycparser | `2.23` | `3.0` | [PyPI](https://pypi.org/project/pycparser/3.0/); review together with BinSync dependency migration |
| libbs | `3.3.3` | `3.8.1` | [PyPI](https://pypi.org/project/libbs/3.8.1/); deprecated shim depending on `declib` |
| binsync | `5.11.2` | `5.15.4` | [PyPI](https://pypi.org/project/binsync/5.15.4/); now requires `declib[ghidra]>=4.0.1` |
| headless-ida | `0.6.7` | `0.6.8` | [PyPI](https://pypi.org/project/headless-ida/0.6.8/) |
| idapro | `0.0.10` | `0.0.11` | [PyPI](https://pypi.org/project/idapro/0.0.11/); pinned in two files |
| ida-hrtng | `eb6b9c203a5f` | `v3.9.114` | [Release](https://github.com/KasperskyLab/hrtng/releases/tag/v3.9.114); newer HEAD also exists |
| ida-lifter | `2.2.0` | `2.7.0` | [Release](https://github.com/19h/ida-lifter/releases/tag/v2.7.0) |
| ida-mcp-rs | `9.3.1` | `9.4.5` | [Stable release](https://github.com/blacktop/ida-mcp-rs/releases/tag/v9.4.5); 9.5 beta excluded |
| ida-mcp | `0.8.1` | `v20261003.0.1` | [Release](https://github.com/HexRaysSA/ida-mcp/releases/tag/v20261003.0.1); versioning changed to CalVer |
| zeromcp | `1.9.0` | `1.10.3` | [PyPI](https://pypi.org/project/zeromcp/1.10.3/) |
| ida-nexus | `0.9.1` | `0.13.3` | [Release](https://github.com/HexRaysSA/ida-nexus/releases/tag/v0.13.3) |
| ida-sigmaker | `1.6.0` | `1.15.0` | [Release](https://github.com/mahmoudimus/ida-sigmaker/releases/tag/v1.15.0) |
| ida-structor | `1.0.0` | `2.2.0` | [Release](https://github.com/19h/ida-structor/releases/tag/v2.2.0); major upgrade |
| ida-theme-explorer | `1.0.2` | `1.0.3` | [Release](https://github.com/kevinmuoz/ida-theme-explorer/releases/tag/v1.0.3) |

IDA Code Mode `0.6.1` was renamed upstream to IDA Nexus. Treat it as a migration to the existing Nexus package, not an independent Code Mode version bump.

### Pi packages and extensions

Commit targets are source updates, not necessarily published releases. Coordinate upgrades with Pi compatibility and refresh extension lockfiles where used.

| Package / extension | Current | Available | Evidence / constraint |
|---|---|---|---|
| Pi coding agent | `0.84.4` | `1.1.0` | [Release](https://github.com/earendil-works/pi/releases/tag/v1.1.0); major upgrade |
| pi-anthropic-oauth | `0.1.11` | Commit `22db92c832d3`, package version `0.3.1` | [Commit](https://github.com/leohenon/pi-anthropic-oauth/commit/22db92c832d3e9962fd1c73355b6dfd2975d60cd); requires newer Pi |
| pi-diff | `0.1.6` | `0.9.2` | [Release](https://github.com/heyhuynhgiabuu/pi-diff/releases/tag/v0.9.2) |
| pi-pretty | `0.4.2` | `0.6.31` | [Release](https://github.com/heyhuynhgiabuu/pi-pretty/releases/tag/v0.6.31); Pi 1.1 support |
| pi-queue-picker | `1.0.3` | `1.0.5` | [npm](https://registry.npmjs.org/@kaiserlich-dev/pi-queue-picker) |
| pi-web-access | `0.27.0` | `0.37.0` | [npm](https://registry.npmjs.org/pi-web-access); check local patch |
| context-guard | `3bae6e62a296` | `pi-mono-context-guard@1.8.0` | [Release](https://github.com/emanuelcasco/pi-mono-extensions/releases/tag/pi-mono-context-guard%401.8.0) |
| guardrails | `bec4c8be8ed9` (`0.17.1`) | `0.19.0` | [Release](https://github.com/aliou/pi-guardrails/releases/tag/v0.19.0) |
| pi-claude-bridge | `9e3fee560fb9` (`0.7.0`) | `0.9.2` | [Release](https://github.com/elidickinson/pi-claude-bridge/releases/tag/v0.9.2) |
| pi-codex-conversion | `1dc70f423da4` (`1.5.13`) | `1.5.16` | [Release](https://github.com/IgorWarzocha/pi-codex-conversion/releases/tag/v1.5.16); repository archived |
| pi-codex-fast | `ea393bf8b1f5` | Commit `d83b218459f0` | [Commit](https://github.com/calesennett/pi-codex-fast/commit/d83b218459f02977222d0e85501bf98b3bafcb05) |
| pi-codex-goal | `529eb81ccd45` (`0.2.0`) | `0.6.0` | [Release](https://github.com/fitchmultz/pi-codex-goal/releases/tag/v0.6.0) |
| pi-fff | `e84b6258bd59` | `0.1.13` | [Release](https://github.com/ShpetimA/pi-fff/releases/tag/v0.1.13) |
| pi-mouse | `1c66f0a7aa64` | `pi-mouse-v0.1.1` | [Repository](https://github.com/alasano/house-of-pi); select package-specific tag, not unrelated monorepo releases |
| pi-tool-display | `7d049f13b91a` (`0.4.0`) | `0.5.0` | [Repository](https://github.com/MasuRii/pi-tool-display) |
| pi-workflow-kit | `a81a633aadb0` (`1.4.0`) | `2.8.1` | [Repository](https://github.com/yinloo-ola/pi-workflow-kit); major upgrade |
| processes | `ffbbda06e97e` (`0.9.3`) | `0.13.2` | [Repository](https://github.com/aliou/pi-processes) |
| santychuy-mermaid | `c4bd7b9d459b` | Commit `37f5b5298b69` touching Mermaid | [Repository](https://github.com/santychuy/pi-setup) |
| subagents | `a9b17bb71868` | `0.76.1` | [Repository](https://github.com/nicobailon/pi-subagents); refresh bundled lockfile |
| tasks | `00ecbd8110f1` | Commit `29180d72498b` | [Repository](https://github.com/tintinweb/pi-tasks); current pin is newer than release `0.9.0` |
| toolchain | `7b06b2804a6f` | `0.10.2` | [Repository](https://github.com/aliou/pi-toolchain) |
| web-providers | `4f2450563e2e` | `4.7.0` | [Successor repository](https://github.com/mavam/webfox); renamed to webfox |
| pi-token-usage (commented out) | `0.3.0` | `0.4.0` | [npm](https://registry.npmjs.org/@alexanderfortin/pi-token-usage) |

### Herdr plugins and flakes

| Package | Current | Available | Evidence / constraint |
|---|---|---|---|
| collie | `1.6.0` | `1.17.2` | [Repository](https://github.com/AltanS/collie) |
| herdr-worktrunk | Commit `8ceca541de8f` | Commit `f9df9ba700b8` | [Repository](https://github.com/devashish2203/herdr-worktrunk); latest release `0.7.0` is older than current pin |
| herdr-auto-title | `0.4.0` | `0.13.0` | [Repository](https://github.com/kryptamine/herdr-auto-title); default title behavior changed |
| herdr-annotate | `0.3.0` | Commit `e3ca7e88ada0`, plugin `0.9.0` | [Repository](https://github.com/plannotator/herdr-annotate); no release tags |
| herdr-resurrect | Commit `5afa6755d4f3` | Commit `109a9376549e` | [Repository](https://github.com/ntindle/herdr-resurrect) |
| devenv | `2.2.2` | `2.4.0` | [Release](https://github.com/cachix/devenv/releases/tag/v2.4.0) |
| hunk | `0.22.0` | `0.23.0` | [Release](https://github.com/modem-dev/hunk/releases/tag/v0.23.0) |

### Containers

| Container | Current | Available | Evidence / constraint |
|---|---|---|---|
| changedetection.io | `0.55.8` | `0.60.8` | [Registry](https://hub.docker.com/r/dgtlmoon/changedetection.io/tags) |
| Kaneo | `2.22.0` | `2.35.0` | [Release](https://github.com/usekaneo/kaneo/releases/tag/v2.35.0) |
| Kokoro FastAPI | `0.8.1` | `0.9.0` | [Release](https://github.com/remsky/Kokoro-FastAPI/releases/tag/v0.9.0); integrated web UI |
| Logto | `1.43.0` | `1.44.0` | [Registry](https://hub.docker.com/r/svhd/logto/tags) |
| Memos | `0.30.0` | `0.31.0` | [Registry](https://hub.docker.com/r/neosmemo/memos/tags) |
| multi-scrobbler | `0.16.5` | `0.19.2` | [Registry](https://hub.docker.com/r/foxxmd/multi-scrobbler/tags) |
| NocoDB | `2026.08.1` | `2026.09.1` | [Registry](https://hub.docker.com/r/nocodb/nocodb/tags) |
| Postiz | `2.23.0` | `2.25.0` | [Release](https://github.com/gitroomhq/postiz-app/releases/tag/v2.25.0) |
| Solidtime | `0.20.0` | `0.21.0` | [Registry](https://hub.docker.com/r/solidtime/solidtime/tags) |
| Stump | `0.1.6` | `0.1.10` | [Registry](https://hub.docker.com/r/aaronleopold/stump/tags) |
| Sure | `0.7.4` | `0.7.5-hotfix.2` | [Stable release](https://github.com/we-promise/sure/releases/tag/v0.7.5-hotfix.2); alpha excluded |
| Twenty | `2.37.0` | `2.45.6` | [Registry](https://hub.docker.com/r/twentycrm/twenty/tags) |

OpenClaw Gateway has upstream release [2026.9.9](https://github.com/openclaw/openclaw/releases/tag/v2026.9.9). Its current image is digest-pinned; verify the desired release's registry digest before replacing it. The pinned digest's exact release mapping was not independently established.

### Migration-only, floating, or unresolved cases

- OpenClaw desktop: newer release `2026.9.9` exists, but its assets contain no Linux AppImage. Keep `2026.9.5` for this packaging path until a newer compatible artifact is available.
- Pi `goal` and `rtk-rewrite`: both selected package directories are absent from [current pi-stuff HEAD](https://github.com/baggiiiie/pi-stuff/tree/c49af840f7abb7494df9ee2d3f9f562a2ecbe0ad). A direct commit bump cannot preserve the existing extraction paths.
- Pi memory: upstream flattened extension directories; review the extraction path before updating the disabled integration.
- Pi better-messages-cache: upstream archived the repository; latest commit `7798b5f49366` is a deprecation note, not a useful feature upgrade.
- Msty: derivation label `1.0` does not establish the downloaded binary's version. [Msty Studio 2.9.6](https://msty.ai/resources/changelog/studio/#msty-2.9.6) exists, but updating requires reviewing the product and download transition.
- VMProtect: `demo` is not a release version. [The download page](https://vmpsoft.com/files) lists `3.10.6`; compare the fetched demo content before claiming an upgrade.
- Tern: latest version could not be established from the authenticated [build endpoint](https://build.stencil.so/tern).
- Octo-fiesta: `dev` floats; [release v0.11](https://github.com/V1ck3s/octo-fiesta/releases/tag/v0.11) exists, but switching requires verifying a matching image tag.
- Disabled Discord overlay: floating URL currently serves `1.0.161`; the existing content hash's release version was not established.
- Disabled Mutter overlay: newer branch commit `29a72bfb0bdb` exists; review whether the overlay is still needed before changing it.
- PostgreSQL 16: newer stable major lines exist. A major change requires a database migration, not just changing the package attribute or image tag.
- Release/channel selectors and major selections are not exact package pins. The research did not refresh or comprehensively compare the resolved `flake.lock` revisions.

### Pins with no newer stable release or source revision found

- Software: Antigravity, aw-watcher-media-player, Binary Ninja, binja-headless, Choosr, Detect It Easy, disktree, ghidra-cli, helix-file-watcher, Herdr GPUI, Herdr, Oh My Pi, Paper Mono, QMD, Radius2, and Solidtime desktop. Solidtime desktop has a newer beta, excluded from stable targets.
- IDA: SDK source, bitopt, ida-domain, D810, guides, WakaTime, and IDASQL. The SDK tag already matches the pin; D810's older `v0.1` tag is not an upgrade.
- Pi: agentic-compaction, tintinweb-pi-subagents, askuserquestion, fzf, Gurpartap Mermaid, nupi, curated-themes, diff-review, dynamic-workflows, pane, ptc, subdir-context, verbosity-control, and sub-bar.
- Other plugins: BleachHack, VS Code JetBrains icon theme, Caddy DuckDNS, steel-pty, and microscopehx.
- Same container repository or release line: browserless/chrome, standalone Kokoro UI, lobe-chat-database, Maloja, PostgreSQL 16/17 point-release tags, Traggo, WatchYourLAN, and Ziit. Browserless v2 and LobeHub v2 require repository/product migrations rather than bumps within the old image repositories.

