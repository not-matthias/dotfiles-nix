# Pi extension sources fetched from GitHub.
# Each entry has:
#   src       - the fetched source
#   resources - which pi resource directories to symlink (relative to src)
{pkgs}: let
  call = f: f {inherit (pkgs) fetchFromGitHub;};
  withRuntimeDeps = args: pkgs.callPackage ./with-runtime-deps.nix args;
  agentStuff = import ./agent-stuff.nix {inherit pkgs;};
in
  {
    fzf = {
      src = withRuntimeDeps {
        src = call (import ./fzf.nix);
        npmDepsHash = "sha256-Ewq0UJfXjuMx6KoCDf/PYhtv4VM4Cqrw3pyX4mXHxow=";
      };
      # Root-level index.ts + package.json
      resources.extensions = ".";
    };

    mermaid = {
      src = withRuntimeDeps {
        src = call (import ./mermaid.nix);
        npmDepsHash = "sha256-rHFkSF+v9MeXXfq8x7Vl9al7EmLgGrC1AMH+WVyxviA=";
      };
      # Root-level index.ts + package.json
      resources.extensions = ".";
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

    rtk = {
      src = call (import ./rtk.nix);
      # Root-level index.ts + package.json
      resources.extensions = ".";
    };

    tasks = {
      src = withRuntimeDeps {
        src = call (import ./tasks.nix);
        npmDepsHash = "sha256-7FT8wePpkEfLbHXZkLQinbWAdvYNJn7V/UZmWXy59K8=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    pi-subagents = {
      src = call (import ./pi-subagents.nix);
      # Whole repo is the extension (index.ts, package.json at root)
      resources.extensions = ".";
    };

    sub-bar = {
      src = call (import ./sub-bar.nix);
      # Use workspace package path so ../pi-sub-core/index.ts resolves inside the fetched monorepo
      resources.extensions = "packages/sub-bar";
    };
  }
  // agentStuff
