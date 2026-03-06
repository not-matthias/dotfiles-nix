{
  pkgs,
  user,
  ...
}: {
  imports = [
    # CLI programs
    ../../modules/home/programs/atuin.nix
    ../../modules/home/programs/bat.nix
    ../../modules/home/programs/btop.nix
    ../../modules/home/programs/cli-agents
    ../../modules/home/programs/direnv.nix
    ../../modules/home/programs/editorconfig.nix
    ../../modules/home/programs/fish
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/gitui.nix
    ../../modules/home/programs/helix.nix
    ../../modules/home/programs/jj.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/rust.nix
    ../../modules/home/programs/starship.nix
    ../../modules/home/programs/tmux
    ../../modules/home/programs/zellij.nix
    ../../modules/home/programs/zoxide.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Rust tools
      navi
      yazi
      eza
      bottom
      tealdeer
      kalker
      ripgrep
      dust
      topgrade
      hexyl
      fd
      delta
      any-nix-shell
      duf

      # Useful tools
      python3

      # Others
      gping
      ouch
      fzf
      procs
      bun
    ];
  };

  programs.home-manager.enable = true;
}
