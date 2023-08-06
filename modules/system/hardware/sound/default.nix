{
  imports = [(import ./pulseaudio.nix)];

  sound.enable = true;
  security.rtkit.enable = true;
}
