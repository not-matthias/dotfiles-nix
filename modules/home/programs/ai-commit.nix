{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.ai-commit;
  selectedModel =
    if cfg.model != null
    then cfg.model
    else if cfg.provider == "claude"
    then "haiku"
    else "gpt-5.3-codex";

  package = pkgs.writeShellScriptBin "ai-commit" ''
        set -euo pipefail

        if ${pkgs.git}/bin/git diff --cached --quiet; then
          echo "Nothing staged to commit."
          exit 1
        fi

        diff=$(${pkgs.git}/bin/git diff --cached)
        log=$(${pkgs.git}/bin/git log -20 --pretty=format:"%s")

        prompt="Generate exactly 3 semantic commit messages for this diff, one per line. Follow Conventional Commits: <type>(<scope>): <summary>. Scope is optional. Be specific about *why* not *what*. Max 72 chars each. Output ONLY the 3 messages, no numbering, no extra text.

    Recent commits for style:
    $log"

        case "${cfg.provider}" in
          claude)
            messages=$(echo "$diff" | ${pkgs.claude-code}/bin/claude -p --model "${selectedModel}" "$prompt")
            ;;
          codex)
            messages=$(echo "$diff" | ${pkgs.bun}/bin/bunx @openai/codex@latest exec --model "${selectedModel}" "$prompt")
            ;;
          *)
            echo "Unsupported provider: ${cfg.provider}"
            exit 1
            ;;
        esac

        msg=$(echo "$messages" | ${pkgs.fzf}/bin/fzf --height=5 --prompt="Pick commit message: " --reverse)

        read -rp "Commit? [Y/e(dit)/n] " choice
        case "''${choice:-y}" in
          [yY]) ${pkgs.git}/bin/git commit -m "$msg" ;;
          [eE]) ${pkgs.git}/bin/git commit -e -m "$msg" ;;
          *)    echo "Aborted." ; exit 1 ;;
        esac
  '';
in {
  options.programs.ai-commit = {
    enable = mkEnableOption "ai-commit - AI-powered commit message generator";

    provider = mkOption {
      type = types.enum ["claude" "codex"];
      default = "claude";
      description = "Which CLI provider to use for commit message generation.";
    };

    model = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "haiku";
      description = "Model name override. Defaults to provider-specific model if null.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [package];
  };
}
