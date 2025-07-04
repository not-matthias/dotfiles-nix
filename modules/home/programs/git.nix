{pkgs, ...}: {
  programs.git = {
    enable = true;
    userEmail = "26800596+not-matthias@users.noreply.github.com";
    userName = "not-matthias";
    lfs.enable = true;
    delta.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.updateRefs = true;
      push.autoSetupRemote = true;
      absorb.autoStageIfNothingStaged = true;
      absorb.oneFixupPerCommit = true;
      absorb.maxStack = 50;
      credential."https://github.com" = {
        helper = "!${pkgs.gitAndTools.gh}/bin/gh auth git-credential";
      };
      # https://stackoverflow.com/questions/16906161/git-push-hangs-when-pushing-to-github
      http.postBuffer = 524288000;

      # Sign by default
      commit.gpgsign = true;
      user.signingKey = "D1B0E3E8E62928DD";
    };
    ignores = [
      ".claude"
      "CLAUDE.md"
      "GEMINI.md"
      "AGENTS.md"
      "SCRATCHPAD.md"
      ".idea"
      ".zed"
      ".vscode"
      "__pycache__"
      ".direnv"
    ];
    aliases = {
      l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
    };
  };
}
