{pkgs, ...}: {
  programs.git = {
    enable = true;
    userEmail = "26800596+not-matthias@users.noreply.github.com";
    userName = "not-matthias";
    extraConfig = {
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential."https://github.com" = {
        helper = "!${pkgs.gitAndTools.gh}/bin/gh auth git-credential";
      };
    };
  };
}
