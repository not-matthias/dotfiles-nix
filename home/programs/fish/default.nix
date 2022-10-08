{
  programs.fish = {
    enable = true;
    plugins = [custom.theme fenv];
    shellAliases = {
      #      cat = "bat";
      #      dc = "docker-compose";
      #      ls = "exa";
      #      ".." = "cd ..";
      #      tree = "exa -T";
    };
    shellInit = fishConfig;
  };
}
