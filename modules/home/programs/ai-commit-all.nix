{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.ai-commit-all;
  commitCfg = config.programs.ai-commit;
  selectedModel =
    if commitCfg.model != null
    then commitCfg.model
    else if commitCfg.provider == "claude"
    then "haiku"
    else "gpt-5-mini";

  package = pkgs.writeShellScriptBin "ai-commit-all" ''
        set -euo pipefail

        git=${pkgs.git}/bin/git
        jq=${pkgs.jq}/bin/jq
        fzf=${pkgs.fzf}/bin/fzf
        pre_commit=${pkgs.pre-commit}/bin/pre-commit

        run_pre_commit="1"
        no_verify="0"

        while [ "$#" -gt 0 ]; do
          case "$1" in
            --skip-pre-commit|-S)
              run_pre_commit="0"
              ;;
            --no-verify|-n)
              no_verify="1"
              ;;
            -h|--help)
              cat <<'EOF'
    Usage: ai-commit-all [--skip-pre-commit|-S] [--no-verify|-n]

    Options:
      --skip-pre-commit, -S  Skip running pre-commit hooks before planning commits.
      --no-verify, -n        Pass --no-verify to git commit.
      -h, --help             Show this help message.
    EOF
              exit 0
              ;;
            *)
              echo "Unknown argument: $1"
              echo "Run 'ai-commit-all --help' for usage."
              exit 1
              ;;
          esac
          shift
        done

        if $git diff --quiet && $git diff --cached --quiet && [ -z "$($git ls-files --others --exclude-standard)" ]; then
          echo "No changes to commit."
          exit 1
        fi

        if [ "$run_pre_commit" = "0" ]; then
          echo "Skipping pre-commit hooks (--skip-pre-commit)."
        elif [ -f .pre-commit-config.yaml ] || [ -f .pre-commit-config.yml ]; then
          echo "Running pre-commit hooks..."
          if ! $pre_commit run --all-files; then
            echo "Warning: pre-commit hooks failed, continuing anyway."
          fi
        else
          echo "No pre-commit config found, skipping hooks."
        fi

        # Unstage everything so we control what goes into each commit
        $git reset HEAD --quiet 2>/dev/null || true

        diff=$($git diff)
        untracked=$($git ls-files --others --exclude-standard)
        untracked_content=""
        if [ -n "$untracked" ]; then
          untracked_content=$(echo "$untracked" | while read -r f; do echo "--- new file: $f ---"; cat "$f" 2>/dev/null || true; done)
        fi
        log=$($git log -20 --pretty=format:"%s")

        base_prompt="You are given a git diff and optionally new untracked files. Split these changes into semantic groups that each deserve their own commit. Each group should be a coherent, atomic change.

        Return ONLY valid JSON (no markdown fences). The format:
        [{\"files\": [\"path/to/file1\", \"path/to/file2\"], \"message\": \"feat(scope): description\"}]

        Rules:
        - Follow Conventional Commits: <type>(<scope>): <summary>. Scope is optional.
        - Be specific about *why* not *what*. Max 72 chars per message.
        - Every changed/untracked file must appear in exactly one group.
        - Order commits logically (dependencies first).

        Changed files:
        $($git diff --name-only)
        $([ -n "$untracked" ] && echo "Untracked files:" && echo "$untracked")

        Recent commits for style:
        $log"

        full_input="$diff"
        if [ -n "$untracked_content" ]; then
          full_input="$full_input

        UNTRACKED FILES:
        $untracked_content"
        fi

        revision_context=""
        previous_plan=""

        while true; do
          prompt="$base_prompt"
          if [ -n "$revision_context" ]; then
            prompt="$prompt

        PREVIOUS PROPOSAL (JSON):
        $previous_plan

        REVISION REQUEST: The user reviewed your previous proposal and wants changes:
        $revision_context

        Keep as much of the previous proposal as possible and only change what's needed to address the revision request."
          fi

          case "${commitCfg.provider}" in
            claude)
              plan=$(echo "$full_input" | ${pkgs.claude-code}/bin/claude -p --model "${selectedModel}" "$prompt")
              ;;
            codex)
              plan=$(echo "$full_input" | ${pkgs.bun}/bin/bunx @openai/codex@latest exec --model "${selectedModel}" "$prompt")
              ;;
            *)
              echo "Unsupported provider: ${commitCfg.provider}"
              exit 1
              ;;
          esac

          # Strip markdown fences if the model wrapped it
          plan=$(echo "$plan" | sed '/^```/d')

          # Validate JSON
          if ! echo "$plan" | $jq empty 2>/dev/null; then
            echo "Error: AI returned invalid JSON:"
            echo "$plan"
            exit 1
          fi

          count=$(echo "$plan" | $jq length)
          echo ""
          echo "Proposed $count commits:"
          echo ""
          for i in $(seq 0 $((count - 1))); do
            msg=$(echo "$plan" | $jq -r ".[$i].message")
            files=$(echo "$plan" | $jq -r ".[$i].files[]")
            echo "  [$((i + 1))] $msg"
            echo "$files" | sed 's/^/      /'
            echo ""
          done

          read -rp "[Y/n/revision message] " choice
          case "''${choice:-y}" in
            [yY]) break ;;
            [nN]) echo "Aborted." ; exit 1 ;;
            *)    previous_plan="$plan" ; revision_context="$choice" ; echo "Revising..." ;;
          esac
        done

        for i in $(seq 0 $((count - 1))); do
          msg=$(echo "$plan" | $jq -r ".[$i].message")
          files=$(echo "$plan" | $jq -r ".[$i].files[]")

          echo "$files" | while read -r f; do
            $git add "$f"
          done

          if [ "$no_verify" = "1" ]; then
            $git commit --no-verify -m "$msg"
          else
            $git commit -m "$msg"
          fi
          echo "Committed: $msg"
        done

        echo ""
        echo "Done! $count commits created."
  '';
in {
  options.programs.ai-commit-all = {
    enable = mkEnableOption "ai-commit-all - split changes into semantic commits";
  };

  config = mkIf cfg.enable {
    home.packages = [package];
  };
}
