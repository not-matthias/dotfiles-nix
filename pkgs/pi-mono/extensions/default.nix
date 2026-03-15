# Pi extension sources fetched from GitHub.
# Each entry has:
#   src       - the fetched source
#   resources - which pi resource directories to symlink (relative to src)
{pkgs}: let
  call = f: f {inherit (pkgs) fetchFromGitHub;};
in {
  multi-pass = {
    src = call (import ./multi-pass.nix);
    resources.extensions = "extensions";
  };

  token-burden = {
    src = call (import ./token-burden.nix);
    # Whole repo is the extension (src/, package.json at root)
    resources.extensions = ".";
  };

  amplike = {
    src = call (import ./amplike.nix);
    resources.extensions = "extensions";
    resources.skills = "skills";
  };

  askuserquestion = {
    src = call (import ./askuserquestion.nix);
    # Whole repo is the extension (src/, package.json at root)
    resources.extensions = ".";
  };

  terminal-theme = {
    src = call (import ./terminal-theme.nix);
    resources.themes = "themes";
  };

  plannotator = {
    src = call (import ./plannotator.nix);
    resources.extensions = "apps/pi-extension";
  };

  readcache = {
    src = call (import ./readcache.nix);
    # Whole repo is the extension (src/, package.json at root)
    resources.extensions = ".";
  };

  notify = {
    src = call (import ./notify.nix);
    # Root-level index.ts + package.json
    resources.extensions = ".";
  };

  claude-agent-sdk = {
    src = call (import ./claude-agent-sdk.nix);
    # Root-level index.ts + package.json
    resources.extensions = ".";
  };

  fzf = {
    src = call (import ./fzf.nix);
    # Root-level extension with .pi/prompts/
    resources.extensions = ".";
    resources.prompts = ".pi/prompts";
  };

  tasks = {
    src = call (import ./tasks.nix);
    # Whole repo is the extension (src/, package.json at root)
    resources.extensions = ".";
  };

  mermaid = {
    src = call (import ./mermaid.nix);
    # Root-level index.ts + package.json
    resources.extensions = ".";
  };

  rtk = {
    src = call (import ./rtk.nix);
    # Root-level index.ts + package.json
    resources.extensions = ".";
  };

  tau = {
    src = call (import ./tau.nix);
    resources.extensions = "extensions";
  };

  aliases = {
    src = call (import ./aliases.nix);
    # Whole repo is the extension (src/, package.json at root)
    resources.extensions = ".";
  };

  agent-stuff = let
    src = call (import ./agent-stuff.nix);
    # Only include selected extensions from pi-extensions/
    filteredExtensions = pkgs.runCommand "agent-stuff-extensions" {} ''
      mkdir -p $out
      for f in answer.ts context.ts multi-edit.ts notify.ts session-breakdown.ts todos.ts uv.ts; do
        cp ${src}/pi-extensions/$f $out/
      done
    '';
  in {
    inherit src;
    resources.extensions = filteredExtensions;
    resources.themes = "pi-themes";
    resources.skills = "skills";
    resources.prompts = "commands";
    # extensions uses an absolute path (derivation output), not a relative subdir
    extensionsAbsolute = true;
  };
}
