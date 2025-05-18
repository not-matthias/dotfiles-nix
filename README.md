# dotfiles-nix
NixOS dotfiles and hardware configurations

## Setup new device

```
nix-shell -p git vscode

git clone github.com/not-matthias/dotfiles-nix
cd dotfiles-nix
code .
```

Then create a new folder inside `hosts` and configure it:
```
cp /etc/nixos/configuration.nix ./hosts/<name>
cp /etc/nixos/hardware-configuration.nix ./hosts/<name>
```

## Installation

```
ln -s `pwd` ~/.config/nixpkgs
sudo nixos-rebuild switch --flake .#laptop
```

## Free memory

(Also try to restart your computer before)

```
nix-collect-garbage -d
# or
nix-collect-garbage --delete-older-than 14d

nix store optimise
nix store gc
```

To delete the derivations, you need `sudo`:
```
sudo nix-collect-garbage -d
```

## Upgrade

```bash
sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixos
sudo nix-channel --update
# Rebuild dotfiles
```

See: https://superuser.com/a/1604695

## Agenix

```
nix run github:ryantm/agenix -- -e test.ages
```

Encrypt existing file:
```
cat file.txt | agenix -e file.age
```

## Errors

### Cached failure of attribute '

Error trace:
```
error: cached failure of attribute 'nixosConfigurations.framework.config.system.build.toplevel'
```

Run with:
```
--option eval-cache false
```

https://discourse.nixos.org/t/cant-switch-to-flakes-error-cached-failure-of-attribute/42933/5

### unable to open database file at /run/current-system/sw/bin/command-not-found

You need to update the system channel (run with sudo!) not your user's channel.

```
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update
```

### Fix home-manager error

```
nix-env --set-flag priority 0 nix-2.11.0
nix-shell '<home-manager>' -A install
```

Source: https://github.com/nix-community/home-manager/issues/2995#issuecomment-1146676866


### Flakes not supported

Add to /etc/nix/nix.conf:
```
# https://nixos.wiki/wiki/Flakes
experimental-features = nix-command flakes
```


### Random: No such file or directory

```
nix-store --verify --check-contents
```

### Devenv error (Cargo.lock not found or package.nix )

Remove `~/.cachix/nix` and try again. 

## References

- https://invidious.namazso.eu/watch?v=AGVXJ-TIv3Y
- https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix
- https://ipetkov.dev/blog/tips-and-tricks-for-nix-flakes/
- https://stel.codes/blog-posts/i3-or-sway-why-not-both/

Dotfiles:
- https://github.com/MatthiasBenaets/nixos-config
- https://github.com/yrashk/nix-home
- https://github.com/Th0rgal/horus-nix-home
