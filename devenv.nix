{pkgs, ...}: {
  # https://devenv.sh/packages/
  packages = [pkgs.treefmt pkgs.mcp-nixos pkgs.ast-grep];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/pre-commit-hooks/
  git-hooks.hooks = {
    alejandra.enable = true;
    shellcheck.enable = true;
    deadnix = {
      enable = true;
      settings.edit = true;
    };
    nix-single-attribute = {
      enable = true;
      name = "Nix single-attribute sets";
      entry = "${pkgs.ast-grep}/bin/ast-grep scan --rule lint/rules/nix-single-attribute.yml";
      files = "\\.nix$";
    };
  };

  # https://devenv.sh/scripts/
  scripts.bd.exec = "nh os switch -H desktop . -- --accept-flake-config";
  scripts.bf.exec = "nh os switch -H framework . -- --accept-flake-config";
  scripts.br.exec = "nh os switch -H raspi . -- --accept-flake-config";
  scripts.bp.exec = "nh os switch -H pc . -- --accept-flake-config";
}
