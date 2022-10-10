# dotfiles-nix
NixOS dotfiles and hardware configurations

## Installation

Install home-manager as described here: https://github.com/nix-community/home-manager#installation

```
ln -s `pwd` ~/.config/nixpkgs
./switch home   # Or system if you are using NixOS
```

## Optimise

```
nix-collect-garbage -d
nix store optimise
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
- https://github.com/MatthiasBenaets/nixos-config
- https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix
- https://ipetkov.dev/blog/tips-and-tricks-for-nix-flakes/

Dotfiles: 
- https://github.com/yrashk/nix-home
- https://github.com/Th0rgal/horus-nix-home
