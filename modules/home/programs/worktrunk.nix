{flakes, ...}: {
  imports = [flakes.worktrunk.homeModules.default];
  programs.fish.shellAbbrs = {
    "wts" = "wt switch";
    "wtsc" = "wt switch --create";
  };
}
