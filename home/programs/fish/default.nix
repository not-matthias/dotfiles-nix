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
      # TODO: Add the others

      "pwd" = "pwd | xclip -selection clipboard && pwd";
    };
    interactiveShellInit = fishPrompt + fishAbbr;
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
