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

## Usage

### Updating the system

To update your system, first update the flake inputs:

```bash
nix flake update
```

Then, rebuild the system with the new inputs:

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

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
