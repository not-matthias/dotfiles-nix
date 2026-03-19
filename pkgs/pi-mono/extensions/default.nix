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

    hashline-edit = {
      src = withRuntimeDeps {
        src = pkgs.runCommand "pi-hashline-edit-with-lock" {} ''
          mkdir -p $out
          cp -R ${call (import ./hashline-edit.nix)}/. $out/
          chmod -R u+w $out
          ${pkgs.nodejs_22}/bin/node -e "
            const fs = require('fs');
            const path = '$out/package.json';
            const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
            delete pkg.peerDependencies;
            fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
          "
          cp ${./hashline-edit-package-lock.json} $out/package-lock.json
        '';
        npmDepsHash = "sha256-keKUkm42SqfWT3heuV5/cLRC2TPP4qaKR8rYoYcHtO0=";
      };
      # Whole repo is the extension (src/, package.json at root)
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

    # Custom local extensions (no fetching needed)
    tab-queue = {
      src = ./custom/tab-queue;
      resources.extensions = ".";
    };
  }
  // agentStuff
