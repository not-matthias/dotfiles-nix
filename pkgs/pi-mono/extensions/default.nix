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

  # token-burden: disabled, requires npm dep gpt-tokenizer
  # claude-agent-sdk: disabled, requires npm dep @anthropic-ai/claude-agent-sdk
  # fzf: disabled, requires npm dep fzf
  # mermaid (ext): disabled, requires npm dep beautiful-mermaid
  # readcache: disabled, requires npm dep diff

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

  notify = {
    src = call (import ./notify.nix);
    # Root-level index.ts + package.json
    resources.extensions = ".";
  };

  tasks = {
    src = call (import ./tasks.nix);
    # Whole repo is the extension (src/, package.json at root)
    resources.extensions = ".";
  };

  pi-subagents = {
    src = call (import ./pi-subagents.nix);
    # Whole repo is the extension (index.ts, package.json at root)
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
    # Exclude skills that collide with our shared skills
    filteredSkills = pkgs.runCommand "agent-stuff-skills" {} ''
      cp -r ${src}/skills $out
      chmod -R u+w $out
      rm -rf $out/commit $out/github $out/mermaid $out/uv
    '';
  in {
    inherit src;
    resources.extensions = filteredExtensions;
    resources.themes = "pi-themes";
    resources.skills = filteredSkills;
    resources.prompts = "commands";
    # extensions and skills use absolute paths (derivation outputs), not relative subdirs
    extensionsAbsolute = true;
    skillsAbsolute = true;
  };
}
