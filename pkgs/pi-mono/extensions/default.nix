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
            delete pkg.devDependencies;
            fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
          "
          cp ${./hashline-edit-package-lock.json} $out/package-lock.json
        '';
        npmDepsHash = "sha256-y1UdDFcMfloiJV/auTRe2+3IfSqYgfYqmK1Dmu50Sxc=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    tasks = {
      src = withRuntimeDeps {
        src = call (import ./tasks.nix);
        npmDepsHash = "sha256-ng0q5Ml2hWPBV7cAnbqCRPukWCCC7WeANcEvyTYPO9c=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    subagents = {
      src = withRuntimeDeps {
        src = call (import ./subagents.nix);
        npmDepsHash = "sha256-RkAlOtCfdARVUDr/NUtf+puNt5YQNQJoqtPvYt9Y9VQ=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    guardrails = {
      src = withRuntimeDeps {
        src = call (import ./guardrails.nix);
        pnpmDepsHash = "sha256-LC6CN/Jktol7Gf4NtOStywJOgXTsuIm1H1hZBeN/RiY=";
      };
      resources.extensions = ".";
    };

    toolchain = {
      src = withRuntimeDeps {
        src = call (import ./toolchain.nix);
        pnpmDepsHash = "sha256-v7bkBl/s0vyXYQacCt/bHdV9Gh1/1r+C6D09KRiyMsQ=";
      };
      resources.extensions = ".";
    };

    processes = {
      src = withRuntimeDeps {
        src = call (import ./processes.nix);
        pnpmDepsHash = "sha256-3i/0RgLh6EtiB9RSYr+OnDpv4mCx1A9/J9rKM5qDXS8=";
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

    # Currently not compatible with hashline-edit
    # "pi-tool-display" = {
    #   src = call (import ./pi-tool-display.nix);
    #   resources.extensions = ".";
    #   extensionsRecursive = true;
    # };

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

    "pi-subdir-context" = {
      src = call (import ./pi-subdir-context.nix);
      resources.extensions = ".";
    };

    "pi-curated-themes" = {
      src = call (import ./pi-curated-themes.nix);
      resources.themes = "themes";
    };

    "pi-diff-review" = {
      src = withRuntimeDeps {
        src = call (import ./pi-diff-review.nix);
        npmDepsHash = "sha256-4BeJ4Tjjpk30xBs/GZ4J3+w3WRHNTAfRk75VUf8Ee3U=";
      };
      resources.extensions = ".";
    };

    "pi-verbosity-control" = {
      src = call (import ./pi-verbosity-control.nix);
      resources.extensions = ".";
    };

    "pi-claude-bridge" = {
      src = withRuntimeDeps {
        src = pkgs.callPackage ./pi-claude-bridge.nix {};
        npmDepsHash = "sha256-wdbGzV9rVpvKrD81qdEl0OpUicYSILnMfR/Rcjvobqo=";
      };
      resources.extensions = ".";
    };

    # Custom local extensions (no fetching needed)
    tab-queue = {
      src = ./custom/tab-queue;
      resources.extensions = ".";
    };
  }
  // agentStuff
