{pkgs, ...}: {
  programs.git = {
    enable = true;
    userEmail = "26800596+not-matthias@users.noreply.github.com";
    userName = "not-matthias";

    extraConfig = {
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential.helper = "${
        pkgs.git.override {withLibsecret = true;}
      }/bin/git-credential-libsecret";
      credential."https://github.com" = {
        helper = "!${pkgs.gitAndTools.gh}/bin/gh auth git-credential";
      };
      # https://stackoverflow.com/questions/16906161/git-push-hangs-when-pushing-to-github
      http.postBuffer = 524288000;
    };
  };
}
