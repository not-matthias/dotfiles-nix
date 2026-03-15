{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.ai-commit;
  package = pkgs.writeShellScriptBin "ai-commit" ''
    set -euo pipefail

    if ${pkgs.git}/bin/git diff --cached --quiet; then
      echo "Nothing staged to commit."
      exit 1
    fi

    diff=$(${pkgs.git}/bin/git diff --cached)
    log=$(${pkgs.git}/bin/git log -20 --pretty=format:"%s")

    messages=$(echo "$diff" | ${pkgs.claude-code}/bin/claude -p --model haiku \
      "Generate exactly 3 semantic commit messages for this diff, one per line. Follow Conventional Commits: <type>(<scope>): <summary>. Scope is optional. Be specific about *why* not *what*. Max 72 chars each. Output ONLY the 3 messages, no numbering, no extra text.

    Recent commits for style:
    $log")

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
  };

  config = mkIf cfg.enable {
    home.packages = [package];
  };
}
