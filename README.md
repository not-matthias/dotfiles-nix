# dotfiles-nix
NixOS dotfiles and hardware configurations

## Installation

```
ln -s `pwd` ~/.config/nixpkgs
nix-env -f '<nixpkgs>' -iA home-manager
home-manager switch
```

TODO: https://github.com/tars0x9752/home#non-nixos-x86_64-linux

## Fix home-manager error 

```
nix-env --set-flag priority 0 nix-2.11.0
nix-shell '<home-manager>' -A install
```

Source: https://github.com/nix-community/home-manager/issues/2995#issuecomment-1146676866


## How to setup

Add to /etc/nix/nix.conf:
```
# https://nixos.wiki/wiki/Flakes
experimental-features = nix-command flakes
```

Setup flake:
```
nix flake init
```



## References

- https://invidious.namazso.eu/watch?v=AGVXJ-TIv3Y
- https://github.com/MatthiasBenaets/nixos-config
- https://ghedam.at/24353/tutorial-getting-started-with-home-manager-for-nix
- https://ipetkov.dev/blog/tips-and-tricks-for-nix-flakes/