{pkgs, ...}: let
  fishPrompt = builtins.readFile ./prompt.fish;
  fishAbbr = builtins.readFile ./abbr.fish;
in {
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "foreign-env";
        src = pkgs.fishPlugins.foreign-env.src;
      }
    ];
    shellAliases = {
    };
    shellAbbrs = {
      "c" = "clear";
      "x" = "exit";
      "find" = "fd";
      "ping" = "gping";
      "cat" = "bat";
      # TODO: Add the others

      "pwd" = "pwd | xclip -selection clipboard && pwd";
    };
    interactiveShellInit =
      ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      ''
      + fishPrompt
      + fishAbbr;
    shellInit = ''
      zoxide init --cmd j fish | source
      mcfly init fish | source
    '';
    functions = {
      fish_greeting = '''';
      fish_mode_prompt = '''';
      dir = ''
        # https://github.com/laughedelic/fish/blob/master/functions/dir.fish
        function dir -a path -d "Creates subdirectories and jumps inside"
        	mkdir -p $path
        	and cd $path
        end
      '';
    };
  };
}
