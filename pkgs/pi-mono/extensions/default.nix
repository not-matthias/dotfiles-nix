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
        npmDepsHash = "sha256-gp9WMX+Xoq+JK0QTORD1ljDtc7NrriaxqNnkMQJGxog=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    tasks = {
      src = withRuntimeDeps {
        src = call (import ./tasks.nix);
        npmDepsHash = "sha256-BuGvosnONRl6H+iJzTXMRXx0S/V9p2+C5+0aAJkXZhM=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    subagents = {
      src = withRuntimeDeps {
        src = call (import ./subagents.nix);
        npmDepsHash = "sha256-eryAWduGdUNWyXHj+H8GFjtUxAOY+sGUqxxIcbeC6ls=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    guardrails = {
      src = withRuntimeDeps {
        src = call (import ./guardrails.nix);
        pnpmDepsHash = "sha256-173+8Mc/AR25Fav07TOT281YX7fjcPD3g/jOyOQ8ziQ=";
      };
      resources.extensions = ".";
    };

    toolchain = {
      src = withRuntimeDeps {
        src = call (import ./toolchain.nix);
        pnpmDepsHash = "sha256-mVJH0BX0dV/lFWdve2JQotWbbpALXwoFoKeBzxqMbGA=";
      };
      resources.extensions = ".";
    };

    processes = {
      src = withRuntimeDeps {
        src = call (import ./processes.nix);
        pnpmDepsHash = "sha256-kksuQ/MQSNtZQta0UntQD38LuNXFz6dAR5HHIHplJ80=";
      };
      resources.extensions = ".";
    };

    "pi-ptc" = {
      src = withRuntimeDeps {
        src = call (import ./pi-ptc.nix);
        npmDepsHash = "sha256-5qnicFVwaHGgM+yVTrRtwwMC2RF7huX66o8+XFWsc64=";
      };
      resources.extensions = ".";
    };

    "pi-memory" = {
      src = withRuntimeDeps {
        src = pkgs.runCommand "pi-memory-extension-src" {} ''
          mkdir -p $out
          cp -R ${call (import ./pi-memory.nix)}/extensions/pi-memory/. $out/
        '';
        npmDepsHash = "sha256-EZj2c5kGW3rjZEAhijaOZiILqKhe0hoYJSH+Knrw2ao=";
      };
      resources.extensions = ".";
      resources.skills = "skills";
    };

    # Custom local extensions (no fetching needed)
    tab-queue = {
      src = ./custom/tab-queue;
      resources.extensions = ".";
    };
  }
  // agentStuff
