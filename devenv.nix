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
  scripts.bd.exec = "nh os switch -H desktop .";
  scripts.bf.exec = "nh os switch -H framework .";
  scripts.br.exec = "nh os switch -H raspi .";
}
