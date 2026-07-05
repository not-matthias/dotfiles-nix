{pkgs, ...}: {
  home.packages = [pkgs.lazygit];

  programs.fish.shellAliases = {
    gitui = "lazygit";
    lg = "lazygit";
  };
}
