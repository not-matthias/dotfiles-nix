{
  pkgs,
  unstable,
  ...
}: {
  programs.jujutsu = {
    enable = true;
    package = unstable.jujutsu;
    settings = {
      user = {
        name = "not-matthias";
        email = "26800596+not-matthias@users.noreply.github.com";
      };

      ui = {
        default-command = "log";
        diff-editor = ":builtin";
        pager = "${pkgs.delta}/bin/delta";
      };

      # Sign commits by default
      signing = {
        behavior = "own";
        backend = "gpg";
        key = "D1B0E3E8E62928DD";
      };

      # Git interop settings
      git = {
        auto-local-bookmark = true;
        push-branch-prefix = "push-";
      };

      # Color and formatting
      colors = {
        "working_copy" = "green";
        "current_operation" = "blue";
      };

      # Template aliases for common log formats
      templates = {
        log_compact = "builtin_log_compact";
        log_comfortable = "builtin_log_comfortable";
      };
    };
  };

  # Add jj shell completions for fish
  programs.fish.interactiveShellInit = ''
    source (${pkgs.jujutsu}/bin/jj util completion fish | psub)
  '';
}
