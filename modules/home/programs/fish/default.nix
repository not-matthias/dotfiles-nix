{
  pkgs,
  unstable,
  ...
}: let
  fishPrompt = builtins.readFile ./prompt.fish;
in {
  home.packages = with pkgs; [
    trash-cli
  ];
  programs.fish = {
    enable = true;
    shellAbbrs = {
      "c" = "clear -x"; # keep the scrollback buffer
      "clear" = "clear -x";
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
      "rm" = "trash-put";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      "gca" = "git commit --amend --no-edit";
      "gc" = "git checkout";
      "gcm" = "git commit -m";
      "gs" = "git status";
      "ga" = "git add -A";
      "gp" = "git pull";
      "gd" = "git diff";
      "gdc" = "git diff";
      "gps" = "git push";
      "gpsf" = "git push --force-with-lease";
      "grbi" = "git rebase -i";
      "grba" = "git rebase --abort";
      "gwip" = "git commit -m \"chore: wip [skip ci]\" --no-verify";

      "btm" = "btm --battery";
      "ps" = "procs";

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
        atuin init fish --disable-up-arrow | source
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

      # FIXME: We still have to use 'export GRANTED_ALIAS_CONFIGURED="true"' when running with bash
      assume = ''
        set -x GRANTED_ALIAS_CONFIGURED "true"
        source ${unstable.granted}/share/assume.fish $argv
        set -e GRANTED_ALIAS_CONFIGURED
      '';
      nf = ''
        function nf -d "Open folder with Nemo"
          nemo . > /dev/null 2>&1 &
        end
      '';
    };
  };
}
