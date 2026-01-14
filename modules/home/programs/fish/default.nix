{
  pkgs,
  unstable,
  ...
}: let
  fishPrompt = builtins.readFile ./prompt.fish;
in {
  home.packages = with pkgs; [
    trash-cli
    prek
  ];
  programs.fish = {
    enable = true;
    shellAbbrs = {
      "c" = "clear -x"; # keep the scrollback buffer
      "clear" = "clear -x";
      "x" = "exit";

      "z" = "zeditor . && exit";
      "co" = "code . && exit";

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
      "cd.." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      "btm" = "btop";
      "ps" = "procs";

      # di = direnv
      "did" = "direnv disallow";
      "dil" = "direnv allow";

      # db = distrobox
      "dbe" = "distrobox enter";

      "dl3" = "yt-dlp -x --continue --audio-format mp3 --audio-quality 0  --format bestaudio --embed-metadata";
      "dl4" = "yt-dlp -f bestvideo+bestaudio --merge-output-format mp4 --continue";

      "cc" = "bunx @anthropic-ai/claude-code";
      "ccc" = "bunx @anthropic-ai/claude-code --continue";
      "ccr" = "bunx @anthropic-ai/claude-code --resume";

      # pre-commit (using prek)
      "pc" = "prek";
      "pcr" = "prek run --all-files";
      "pci" = "prek install";
      "pcu" = "prek auto-update";
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
    };
  };
}
