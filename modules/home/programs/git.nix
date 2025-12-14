{pkgs, ...}: {
  home.packages = with pkgs; [
    git-absorb
  ];

  programs.git = {
    enable = true;
    userEmail = "26800596+not-matthias@users.noreply.github.com";
    userName = "not-matthias";
    lfs.enable = true;
    delta.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.updateRefs = true;
      push.autoSetupRemote = true;
      absorb.autoStageIfNothingStaged = true;
      absorb.oneFixupPerCommit = true;
      absorb.maxStack = 50;
      credential."https://github.com" = {
        helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
      # https://stackoverflow.com/questions/16906161/git-push-hangs-when-pushing-to-github
      http.postBuffer = 524288000;

      # Sign by default
      commit.gpgsign = true;
      user.signingKey = "D1B0E3E8E62928DD";
    };
    ignores = [
      ".claude"
      "CLAUDE.md"
      "GEMINI.md"
      "AGENTS.md"
      "SCRATCHPAD.md"
      ".idea"
      ".zed"
      ".vscode"
      "__pycache__"
      ".direnv"
      ".envrc"
      ".shell.nix"
    ];
    aliases = {
      l = "log --pretty=oneline -n 10 --graph --abbrev-commit --decorate=no";
      lb = "log --pretty=oneline -n 10 --graph --abbrev-commit";
    };
  };

  programs.fish = {
    shellAbbrs = {
      "gl" = "git l";
      "glb" = "git lb";
      "gca" = "git commit --amend --no-edit";
      "gc" = "git checkout";
      "gcl" = "git checkout";
      "gcb" = "git checkout -b";
      "gcm" = "git commit -m";
      "gbp" = "gbp";
      "gs" = "git status";
      "gsp" = "git stash pop";
      "ga" = "git add -A";
      "gp" = "git pull";
      "gd" = "git diff";
      "gps" = "git push";
      "gpl" = "git pull";
      "gpsf" = "git push --force-with-lease";
      "grbi" = "git rebase -i";
      "grba" = "git rebase --abort";
      "gwip" = "git commit -m \"chore: wip [skip ci]\" --no-verify";
    };
    functions = {
      # Git helper functions with fzf
      _ensure_git_repo = ''
        function _ensure_git_repo -d "Check if we're in a git repository"
          git rev-parse --is-inside-work-tree &>/dev/null
          or return 1
        end
      '';

      gco = ''
        function gco -d "Fuzzy checkout a branch"
          _ensure_git_repo || return 1
          # If argument provided, use it directly; otherwise use fzf
          if test (count $argv) -gt 0
            git checkout "$argv"
          else
            set -l branch (git branch --list | sed 's/^[* \t]*//g' | fzf --preview 'git log -10 --oneline {1}')
            and test -n "$branch" && git checkout "$branch"
          end
        end
      '';

      gcof = ''
        function gcof -d "Fuzzy checkout with commit history preview"
          _ensure_git_repo || return 1
          # If argument provided, use it directly; otherwise use fzf
          if test (count $argv) -gt 0
            git checkout "$argv"
          else
            set -l branch (git branch --list | sed 's/^[* \t]*//g' | fzf --preview 'git log --color=always -10 --oneline {1}' --ansi)
            and test -n "$branch" && git checkout "$branch"
          end
        end
      '';

      gbp = ''
        function gbp -d "Fuzzy select base branch for PR"
          _ensure_git_repo || return 1
          set -l base_branch (git branch -a | sed 's/^[* ] //' | sed 's|remotes/[^/]*/||' | sort -u | fzf --preview 'git log --color=always -10 --oneline {1}' --ansi)
          if test -n "$base_branch"
            echo "Creating PR with base branch: $base_branch"
            gh pr create --base $base_branch
          end
        end
      '';

      # Alternative: Interactive base branch selection that just outputs the name
      _git_base_branch = ''
        function _git_base_branch -d "Select base branch (outputs branch name)"
          _ensure_git_repo || return 1
          git branch -a | sed 's/^[* ] //' | sed 's|remotes/[^/]*/||' | sort -u | fzf --preview 'git log --color=always -10 --oneline {1}' --ansi
        end
      '';
    };
  };
}
