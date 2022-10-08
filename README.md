# dotfiles-nix
NixOS dotfiles and hardware configurations

## Installation

```
ln -s `pwd` ~/.config/nixpkgs
nix-env -f '<nixpkgs>' -iA home-manager
home-manager switch
```

TODO: https://github.com/tars0x9752/home#non-nixos-x86_64-linux


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