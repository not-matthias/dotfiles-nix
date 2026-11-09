# Maintenance

[Back to the overview](../README.md)

These configurations assume an existing NixOS installation, except for the standalone Jetson Home Manager configuration. Commands below run from the repository root. Review host-specific hardware, accounts, secrets, and network settings before activating a configuration.

## Nix and flakes

Nix must have `nix-command` and `flakes` enabled. On an installation that does not already enable them, add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf`.

Clone the repository with `git clone https://github.com/not-matthias/dotfiles-nix` and enter the checkout. Some inputs require authenticated SSH access; some applications require separately downloaded archives or licenses.

## Add a host

1. Create `hosts/<name>/default.nix`, using a host with similar hardware as a reference.
2. Copy the new machine's `/etc/nixos/hardware-configuration.nix` into that directory and import it. Review filesystem identifiers, boot settings, graphics, and networking.
3. Register the host in [hosts/default.nix](../hosts/default.nix) through `nixosBox`, supplying its architecture, package set, directory name, and domain.
4. Review the shared username in [flake.nix](../flake.nix), account-specific paths, and services that depend on encrypted secrets or personal endpoints. Use your own secrets and recipients.
5. Stage new files so the Git-backed flake includes them. Build the new target before activating it.

Only exported targets can be built. Check [hosts/default.nix](../hosts/default.nix), not just directory names. `pc` and `desktop` are separate configurations.

## Build and activate

For the configured Framework machine:

1. Build without activation: `sudo nixos-rebuild build --flake .#framework`.
2. Activate: `sudo nixos-rebuild switch --flake .#framework`.

Use the intended host target on another machine. A successful build does not establish that hardware settings or runtime services are correct.

## Jetson: Home Manager only

Jetson manages a user environment rather than a NixOS system. Its output is `not-matthias@jetson`; see [the user configuration](../hosts/jetson/home.nix).

1. Bootstrap Home Manager using the repository's input: `nix run --inputs-from . home-manager -- switch --flake '.#not-matthias@jetson'`.
2. After activation puts Home Manager on `PATH`, update with `home-manager switch --flake '.#not-matthias@jetson'`.

Do not use `nixos-rebuild` for this output.

## Update dependencies

Run `nix flake update`, review `flake.lock`, then build and activate the intended host. For a targeted update, supply the input name, such as `nix flake update niri`.

Nix registry entries affect shorthand references used by the CLI, not the dependencies pinned in this repository's lockfile. Inspect them with `nix registry list`; use flake updates to change repository dependencies.

OMP is pinned separately in [pkgs/oh-my-pi.nix](../pkgs/oh-my-pi.nix), not in `flake.lock`. Version 18.18.5 (2026-11-09) uses the upstream binary checksum. Rebuild and activate the host configuration after changing the pin.

## Garbage collection

Deleting generations removes rollback options. Keep any generation you may need before collecting its store paths.

- Remove user generations older than 14 days: `nix-collect-garbage --delete-older-than 14d`.
- Remove all old user generations: `nix-collect-garbage -d`.
- Remove all old system generations: `sudo nix-collect-garbage -d`.
- Collect unreferenced paths without deleting generations: `sudo nix store gc`.
- Deduplicate identical store files: `sudo nix store optimise`.

## Secrets

Secrets use [agenix](https://github.com/ryantm/agenix). Recipient keys are defined in [secrets/secrets.nix](../secrets/secrets.nix). The encrypted files are intended for these machines; copying them does not grant access to their contents.

From `secrets/`, edit a secret with `agenix -e <secret-name>.age`. When creating a secret, configure its recipients in `secrets.nix` before encrypting it. Keep plaintext credentials out of Git and Nix expressions, whose contents may be readable in the Nix store.

For failures, see [Troubleshooting](troubleshooting.md).
