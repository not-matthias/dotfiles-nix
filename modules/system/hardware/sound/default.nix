{
  imports = [(import ./pipewire.nix)];

  security.rtkit.enable = true;
}
