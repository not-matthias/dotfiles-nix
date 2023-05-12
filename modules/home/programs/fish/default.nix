{pkgs, ...}: let
  fishPrompt = builtins.readFile ./prompt.fish;
in {
  programs.fish = {
    enable = true;
    shellAliases = {
      # Shortcut for "open **F**older with **N**autilus"
      "nf" = "nautilus . &>/dev/null &";
      "ida" = "wine64 (zoxide query ida76sp1)/ida64.exe 2>/dev/null &";
      "ida32" = "wine64 (zoxide query ida76sp1)/ida.exe 2>/dev/null &";
    };
    shellAbbrs = {
      "c" = "clear";
      "x" = "exit";

      "ns" = "nix-shell -p";
      "find" = "fd";
      "diff" = "delta";
      "ping" = "gping";
      "cat" = "bat";
      "cp" = "fcp";
      "ls" = "exa";
      "tree" = "exa --tree";
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
      "gs" = "git status";
      "ga" = "git add -A";
      "gp" = "git pull";
    };
    interactiveShellInit =
      ''
        eval (${pkgs.direnv}/bin/direnv hook fish)
      ''
      + fishPrompt;
    shellInit = ''
      zoxide init --cmd j fish | source
      mcfly init fish | source
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
