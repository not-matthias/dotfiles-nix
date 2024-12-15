{...}: {
  programs.alacritty = {
    settings = {
      window = {
        dimensions = {
          columns = 100;
          lines = 25;
        };
        padding = {
          x = 5;
          y = 5;
        };
      };
      font = {
        normal = {
          family = "JetBrainsMono";
          style = "Regular";
        };
        size = 10.0;
      };

      # See: https://stackoverflow.com/questions/67463932/is-it-possible-to-make-alacritty-starts-with-tmux
      # shell = {
      #   program = "/etc/profiles/per-user/not-matthias/bin/fish";
      #   args = ["-l" "-c" "tmux attach || tmux"];
      # };

      general.live_config_reload = true;

      # Black background
      colors.primary.background = "#000000";
    };
  };
}
