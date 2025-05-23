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
  scripts.bd.exec = "sudo nixos-rebuild switch --flake .#desktop";
  scripts.bf.exec = "sudo nixos-rebuild switch --flake .#framework";
  scripts.br.exec = "sudo nixos-rebuild switch --flake .#raspi";
}
