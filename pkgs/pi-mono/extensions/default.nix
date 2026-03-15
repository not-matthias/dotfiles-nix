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
    multi-pass = {
      src = call (import ./multi-pass.nix);
      resources.extensions = "extensions";
    };

    token-burden = {
      src = withRuntimeDeps {
        src = call (import ./token-burden.nix);
        pnpmDepsHash = "sha256-TRMoNKN9LtnES/f3PFE8DKc1JoE1vb+PrWwgOl/xF/w=";
      };
      # Whole repo is the extension (package.json pi.extensions points to ./src/index.ts)
      resources.extensions = ".";
    };

    claude-agent-sdk = {
      src = withRuntimeDeps {
        src = call (import ./claude-agent-sdk.nix);
        npmDepsHash = "sha256-MX8nXlde5N2Wrw6Iu0mUE1l9z8/ht1SNB4yU8CT9/28=";
      };
      # Root-level index.ts + package.json
      resources.extensions = ".";
    };

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

    readcache = {
      src = withRuntimeDeps {
        src = call (import ./readcache.nix);
        npmDepsHash = "sha256-+dsZ+44d/N6H4yUBO1cBp2XGMQq0Psid/kopP2W8QYs=";
      };
      # Root-level index.ts + package.json
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

    notify = {
      src = call (import ./notify.nix);
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
  }
  // agentStuff
