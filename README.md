# dotfiles-nix

NixOS dotfiles and hardware configurations for my personal machines.

##  NixOS & Flakes

This repository is managed using NixOS and Nix Flakes. [NixOS](https://nixos.org/) is a Linux distribution with a unique approach to package and configuration management. [Flakes](https://nixos.wiki/wiki/Flakes) are a new feature in Nix that improve reproducibility and composability.

To enable flakes, you need to add the following to your `/etc/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## Installation

### 1. Clone the repository

```bash
nix-shell -p git
git clone https://github.com/not-matthias/dotfiles-nix ~/.config/nixpkgs
cd ~/.config/nixpkgs
```

### 2. Set up a new host

Create a new directory for your host in the `hosts` directory. You can use the existing hosts as a template. You will need to copy the `hardware-configuration.nix` from your new NixOS installation.

```bash
# Example for a new host named "my-new-machine"
mkdir -p hosts/my-new-machine
cp /etc/nixos/hardware-configuration.nix hosts/my-new-machine/
```

You will also need to create a `default.nix` for your new host. This file defines the NixOS configuration for the machine. You can use one of the existing hosts as a starting point.

### 3. Build and activate the configuration

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

Replace `<hostname>` with the name of your host (e.g., `desktop`, `laptop`).

### Jetson (Home Manager only)

The Jetson uses a standalone Home Manager configuration (no NixOS). To set it up on a Jetson device:

```bash
git clone https://github.com/not-matthias/dotfiles-nix
cd dotfiles-nix
nix run home-manager/release-25.11 -- switch --flake .#not-matthias@jetson
```

Once `home-manager` is on your `PATH` (after the first activation), subsequent updates are just:

```bash
home-manager switch --flake .#not-matthias@jetson
```

### Timeguard rules (2026-10-12)

Timeguard reads encrypted rules from `secrets/timeguard-rules.age`. Scheduled
rules use `[[rule.schedule.window]]` for `days`, `start`, and `end`; `mode`
belongs under `[rule.schedule]`. Validate decrypted rules with
`timeguard check --config /etc/timeguard/config.toml --rules-file <rules.toml>`
before re-encrypting and activating.

### TradingView Desktop (2026-10-12)

Framework enables `programs.tradingview.enable` from
`modules/home/programs/tradingview.nix`. It installs TradingView from the pinned
unstable input and registers its desktop entry and `tradingview://` login handler
through Home Manager.

Activate with `sudo nixos-rebuild switch --flake .#framework`, then launch
TradingView and select **Sign in with browser**. Grant access in the browser
and allow it to open TradingView to complete sign-in.

### Grok Bot (2026-10-11)

Framework installs the official Linux Grok Bot through
[llm-agents.nix](https://github.com/numtide/llm-agents.nix/tree/main/packages/grok-bot).
Home Manager sets the `grokbot://` and `sand://` login callback handlers.
Update the pinned package and activate it with:

```bash
nix flake update llm-agents
sudo nixos-rebuild switch --flake .#framework
```

The upstream package disables Chromium's sandbox to work around renderer crashes.
Sign-in requires an eligible [Grok or Cursor plan](https://x.ai/bot).

### Tern local release (2026-10-05)

Framework enables `programs.tern.enable`, which installs Tern 0.4.5 and its Home
Manager desktop entry. Download the closed-beta release from
https://build.stencil.so/tern and import it before building:

```bash
nix-store --add-fixed sha256 ~/Downloads/Tern-0.4.5-linux-x86_64.tar.gz
sudo nixos-rebuild switch --flake .#framework
```

The package supplies its runtime libraries. Sign-in requires a Stencil
closed-beta account.

Install the Herdr plugin with Git and Herdr available on Tern's PATH:

```bash
tern plugin install github.com/gabrielmoreira/herdr-tern-plugin
```

Open Tern's command palette and choose **Open Herdr Session**.

### Plannotator (2026-10-06)

Framework and PC enable `programs.plannotator.enable` to install Plannotator 0.28.5
and manage `~/.plannotator/config.json`. Both use split diffs against the base and
keep unchanged sections collapsed.

### Herdr GPUI (2026-10-07)

Framework enables `programs.herdr-gpui.enable` to install Herdr GPUI 20261007.3
from the pinned upstream Linux release and manage its desktop entry.
Launch **Herdr GPUI** from the application launcher or run `herdr-gpui`.
The Home Manager desktop entry uses the packaged icon, and the package supplies
its Wayland and Vulkan runtime libraries. It connects to the separately installed
Herdr daemon; updates are managed through Nix.

## Usage

### Timeguard recovery (2026-10-09)

When Timeguard is enabled, `timeguard-guard.target` starts at boot and uses
`Upholds=timeguard.service` to bring it back after a stop. Both units refuse manual
stops. Budgeted pauses leave the daemon running and remain available.
This adds friction, not protection against unrestricted root access.

Existing runtime drop-ins can override stop protection. Before activating this
configuration, remove `/run/systemd/system/timeguard.service.d/stop-override.conf`
if present, then reload systemd. Start `timeguard-guard.target` after activation.

### Niri status bar (2026-10-03)

Quickshell starts with `graphical-session.target` and stops with it through
`PartOf`. This prevents restart loops against a closed Wayland socket during
logout or compositor restarts. Niri startup does not restart the bar separately.

### Updating the system

To update your system, first update the flake inputs:

```bash
nix flake update
```

Then, rebuild the system with the new inputs:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

### Niri battery widget (2026-10-04)

The Quickshell battery widget uses UPower. The Niri module enables
`services.upower.enable`; rebuild and activate the system after changing it.
If the widget is missing, check `systemctl status upower` and
`journalctl --user -u quickshell`.

### Garbage Collection

To free up disk space, you can run the garbage collector:

```bash
nix-collect-garbage -d
# or to delete generations older than 14 days
nix-collect-garbage --delete-older-than 14d
```

To delete the derivations, you need to run the command with `sudo`:

```bash
sudo nix-collect-garbage -d
```

You can also optimize the Nix store:
```
nix store optimise
nix store gc
```

### Secrets Management

This repository uses [agenix](https://github.com/ryantm/agenix) to manage secrets. Secrets are encrypted using age and can be safely stored in the repository.

To edit a secret, use the following command:

```bash
agenix -e <secret-name>.age
```

To encrypt a new file:
```
cat file.txt | agenix -e file.age
```

### Taskwarrior sync

2026-09-29: `pc` serves TaskChampion at `https://todo-sync.pcnm.duckdns.org`
through Caddy on the tailnet. The sync daemon listens only on loopback; Taskwarrior
clients use HTTPS and the shared encryption secret managed by agenix. Check the
endpoint with `curl https://todo-sync.pcnm.duckdns.org/` while connected to Tailscale.

### Adding extra registries

```
$ nix registry add nixpkgs-unstable github:NixOS/nixpkgs/nixos-unstable 
$ nix registry list
```

### CLI releases

2026-10-07: Updated OMP to 18.8.3 from the latest upstream release.

2026-10-04: Updated OMP to 18.6.1, Plannotator to 0.27.25, and Herdr to 0.9.3
for upstream fixes to agent tools, review rendering, and terminal input.

### OMP advisor

2026-09-25: OMP installs a global, advisor-only policy at `~/.omp/agent/WATCHDOG.md`.
Edit `modules/home/programs/cli-agents/oh-my-pi/WATCHDOG.md` for review priorities
and the adjacent `config.yml` for advisor settings.

- One advisor uses `modelRoles.advisor` with the default read-only tools.
- At most one non-blocker note is accepted per review update; blockers are exempt.
  This limits advice volume, not model calls or token usage.
- The default catch-up mode is `off`, with three immune turns after an interruption.
- Project `WATCHDOG.md` and `.omp/WATCHDOG.md` files add more specific guidance;
  they do not replace the global policy. Named profiles use their own agent directory.
- Start a new session after activation. Use `/advisor status` to inspect the model,
  usage, and runtime state, or `/advisor off` to disable it for that session.

See the [upstream advisor documentation](https://github.com/can1357/oh-my-pi/blob/main/docs/advisor-watchdog.md)
for discovery, severity, and optional multi-advisor rosters.

## Troubleshooting

### Cached failure of attribute

If you encounter an error like `cached failure of attribute 'nixosConfigurations.framework.config.system.build.toplevel'`, try running the command with the `--option eval-cache false` flag.

### command-not-found error

If you see `unable to open database file at /run/current-system/sw/bin/command-not-found`, you need to update the system channel (run with sudo!) not your user's channel.

```
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update
```

### Devenv error

If you encounter an error related to `devenv` (e.g., `Cargo.lock` not found), try removing the `~/.cachix/nix` directory and running the command again.

## References

- [MatthiasBenaets/nixos-config](https://github.com/MatthiasBenaets/nixos-config)
- [yrashk/nix-home](https://github.com/yrashk/nix-home)
- [Th0rgal/horus-nix-home](https://github.com/Th0rgal/horus-nix-home)
