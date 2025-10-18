{...}: {
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;

    settings = {
      # Define the prompt format to match Fish prompt structure
      # Format: [HH:MM] username@container:directory git_branch>
      # with newline after prompt for user input
      format = "[\\[$time\\] ]($style)$username[@$container](:)$directory$git_branch$git_status$git_metrics$cmd_duration$battery$status$character\n";

      # Time module - [HH:MM] in bright black
      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "bright-black";
        time_format = "%H:%M";
      };

      # Username module - white color, always show
      username = {
        show_always = true;
        style_user = "white";
        style_root = "white";
        format = "[$user]($style)";
      };

      # Container module for distrobox detection
      container = {
        disabled = false;
        style = "white";
        format = "[$name]($style)";
      };

      # Directory module - bright yellow, show only basename
      directory = {
        style = "bright-yellow";
        format = "[$path]($style)";
        truncation_length = 0;
        truncate_to_repo = true; # Don't truncate within git repos
        truncation_symbol = "…/";
        fish_style_pwd_dir_length = 1; # Shows only basename
        home_symbol = "~";
      };

      # Git branch module
      git_branch = {
        style = "white";
        format = "[ $branch]($style)";
      };

      # Git status module
      git_status = {
        style = "white";
        format = "([$all_status$ahead_behind]($style))";
      };

      # Character module - the '>' prompt
      character = {
        success_symbol = "[>](white)";
        error_symbol = "[>](white)";
        vimcmd_symbol = "[>](white)";
      };

      # Command duration - show execution time for slow commands
      cmd_duration = {
        min_time = 500; # Only show if command took >500ms
        format = "[$duration]($style) ";
        style = "yellow";
      };

      # Status indicator - show exit codes on failure
      status = {
        disabled = false;
        format = "[$symbol$status]($style) ";
        symbol = "✗ ";
        not_executable_symbol = "🚫 ";
        not_found_symbol = "❓ ";
        style = "red";
      };

      # Battery indicator - useful for Framework laptop
      battery = {
        full_symbol = "🔋";
        charging_symbol = "⚡";
        discharging_symbol = "💀";
        display = [
          {
            threshold = 10;
            style = "bold red";
          }
          {
            threshold = 30;
            style = "bold yellow";
          }
        ];
      };

      # Git metrics - show added/deleted lines
      git_metrics = {
        disabled = false;
        added_style = "green";
        deleted_style = "red";
        format = "([+$added]($added_style) )([-$deleted]($deleted_style) )";
      };
    };
  };
}
