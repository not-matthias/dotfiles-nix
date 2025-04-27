{
  pkgs,
  unstable,
  ...
}: let
  fishPrompt = builtins.readFile ./prompt.fish;
in {
  programs.fish = {
    enable = true;
    shellAliases = {
      # Shortcut for "open **F**older with **N**autilus"
      "nf" = "nautilus . > /dev/null 2>&1 &";
    };
    shellAbbrs = {
      "c" = "clear";
      "x" = "exit";

      "ns" = "nix-shell -p";
      "find" = "fd";
      "diff" = "delta";
      "cat" = "bat";
      "ls" = "eza";
      "tree" = "eza --tree";
      "df" = "duf";
      "du" = "dust";
      "k" = "kalker";
      "xxd" = "hexyl";
      "tmux" = "zellij";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      "gc" = "git commit";
      "gcm" = "git commit -m";
      "gs" = "git status";
      "ga" = "git add -A";
      "gp" = "git pull";
      "gps" = "git push";
      "btm" = "btm --battery";

      # di = direnv
      "did" = "direnv disallow";
      "dil" = "direnv allow";

      # db = distrobox
      "dbe" = "distrobox enter";

      "dl3" = "yt-dlp -x --continue --audio-format mp3 --audio-quality 0  --format bestaudio --embed-metadata";
      "dl4" = "yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 --continue";
    };
    interactiveShellInit =
      ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      ''
      + fishPrompt;
    shellInit = ''
      any-nix-shell fish --info-right | source
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

      assume = ''
        set -x GRANTED_ALIAS_CONFIGURED "true"
        source ${unstable.granted}/share/assume.fish $argv
        set -e GRANTED_ALIAS_CONFIGURED
      '';
    };
  };
}
