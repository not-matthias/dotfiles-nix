# dotfiles-nix
NixOS dotfiles and hardware configurations


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