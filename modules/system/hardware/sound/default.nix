{
  imports = [(import ./pipewire.nix)];

  sound.enable = true;
  security.rtkit.enable = true;
}
