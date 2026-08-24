{pkgs, ...}: {
  home.packages = with pkgs; [
    # Nix
    nil
    nixd
    alejandra
    nixfmt
    deadnix
    statix

    # Rust
    rust-analyzer

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
    clang-tools
  ];
}
