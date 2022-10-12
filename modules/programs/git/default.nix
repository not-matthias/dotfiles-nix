{
  programs.git = {
    enable = true;
    userEmail = "26800596+not-matthias@users.noreply.github.com";
    userName = "not-matthias";
    extraConfig = {
      pull.rebase = true;
      push.autoSetupRemote = true;
      credential."https://github.com" = {
        helper = "!/etc/profiles/per-user/not-matthias/bin/gh auth git-credential";
      };
    };
  };
}
