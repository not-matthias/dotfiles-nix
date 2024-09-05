{pkgs, ...}: let
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
      "ping" = "gping";
      "cat" = "bat";
      "ls" = "eza";
      "tree" = "eza --tree";
      "df" = "duf";
      "du" = "dust";
      "k" = "kalker";
      "xxd" = "hexyl";
      # "dmesg" = "rmseg";
      "gdb" = "gef";

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
    };
    interactiveShellInit =
      ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      ''
      + fishPrompt;
    shellInit = ''
      zoxide init --cmd j fish | source
      atuin gen-completions --shell fish | source
      atuin init fish --disable-up-arrow | source
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
    };
  };
}
