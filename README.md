# dotfiles-nix
NixOS dotfiles and hardware configurations

## Installation

```
ln -s `pwd` ~/.config/nixpkgs
sudo nixos-rebuild switch --flake .#laptop
```

## Optimise

```
nix-collect-garbage -d
nix store optimise
```

## Upgrade

```bash
sudo nix-channel --add https://nixos.org/channels/nixos-22.11 nixos    
sudo nix-channel --update
# Rebuild dotfiles
```

## Errors

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


## References

- https://invidious.namazso.eu/watch?v=AGVXJ-TIv3Y
- https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix
- https://ipetkov.dev/blog/tips-and-tricks-for-nix-flakes/
- https://stel.codes/blog-posts/i3-or-sway-why-not-both/

Dotfiles: 
- https://github.com/MatthiasBenaets/nixos-config
- https://github.com/yrashk/nix-home
- https://github.com/Th0rgal/horus-nix-home
