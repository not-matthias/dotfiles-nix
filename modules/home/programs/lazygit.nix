{
  pkgs,
  unstable,
  ...
}: {
  programs.lazygit = {
    enable = true;
    # `gui.sidePanels` only exists from 0.63 onwards; stable ships 0.61.
    package = unstable.lazygit;
    settings = {
      git.diffRenderers = [
        {
          colorArg = "always";
          command = "${pkgs.delta}/bin/delta --paging=never";
        }
      ];
      # Default grouping with commits and branches swapped, so commits lands on
      # the [3] jump key. 'files', 'branches' and 'commits' are mandatory.
      gui.sidePanels = [
        ["status"]
        ["files" "worktrees" "submodules"]
        ["commits" "reflog"]
        ["branches" "remotes" "tags"]
        ["stash"]
      ];
    };
  };
}
