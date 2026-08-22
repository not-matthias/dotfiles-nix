{flakes, ...}: {
  imports = [flakes.timeguard.nixosModules.default];
}
