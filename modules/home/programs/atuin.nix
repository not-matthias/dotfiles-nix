{unstable, ...}: {
  programs.atuin = {
    enable = true;
    package = unstable.atuin;
    enableFishIntegration = true;
    settings = {
      filter_mode_shell_up_key_binding = "directory";
      search_mode = "fuzzy";

      # TODO:
      # sync_address = "https://atuin.vpn.maximbaz.com";
    };
  };
}
