{unstable, ...}: {
  programs.atuin = {
    enable = true;
    package = unstable.atuin;
    enableFishIntegration = true;
    settings = {
      # fuzzy: doesn't quite work for me. example: search for env var i set before
      search_mode = "skim";
      # TODO: sync_address
    };
  };
}
