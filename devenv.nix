{pkgs, ...}: {
  # https://devenv.sh/packages/
  packages = [pkgs.treefmt];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks = {
    alejandra.enable = true;
    shellcheck.enable = true;
    deadnix.enable = true;
  };

  # https://devenv.sh/scripts/
  scripts.bd.exec = "sudo nixos-rebuild switch --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=  --flake .#desktop";
  scripts.bf.exec = "sudo nixos-rebuild switch --flake .#framework";
  scripts.br.exec = "sudo nixos-rebuild switch --flake .#raspi";
}
