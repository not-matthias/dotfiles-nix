{unstable, ...}: {
  programs.atuin = {
    enable = true;
    package = unstable.atuin;
    enableFishIntegration = false;
    settings = {
      search_mode = "daemon-fuzzy"; # fuzzy: doesn't quite work for me. example: search for env var i set before
      filter_mode = "directory";
      keymap_mode = "vim-insert";
      secrets_filter = true;
      store_failed = false;
      ai.enabled = false;
    };
  };
}
