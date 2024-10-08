{pkgs, ...}: {
  # https://devenv.sh/packages/
  packages = [pkgs.treefmt];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks = {
    alejandra.enable = true;
    shellcheck.enable = true;
    deadnix.enable = true;
  };

  # https://devenv.sh/scripts/
  scripts.bl.exec = "sudo nixos-rebuild switch --flake .#laptop";
  scripts.bd.exec = "sudo nixos-rebuild switch --flake .#desktop";
  scripts.bf.exec = "sudo nixos-rebuild switch --flake .#framework";
  scripts.bt.exec = "sudo nixos-rebuild switch --flake .#travel";
}
