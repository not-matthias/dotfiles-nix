{pkgs, ...}: let
  clangdOnly = pkgs.runCommand "clangd-only" {} ''
    mkdir -p $out/bin
    ln -s ${pkgs.clang-tools}/bin/clangd $out/bin/clangd
  '';
in {
  home.packages = with pkgs; [
    # Nix
    nil
    nixd
    alejandra
    nixfmt
    deadnix
    statix

    # TOML
    taplo

    # Markdown & Prose
    marksman
    harper
    prettier

    # Python
    pyright
    ruff

    # Web / TypeScript / JSON / YAML
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server

    # Shell
    bash-language-server
    shfmt
    shellcheck

    # C / C++
    clangdOnly
  ];
}
