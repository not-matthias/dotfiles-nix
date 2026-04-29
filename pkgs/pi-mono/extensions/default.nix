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
    askuserquestion = {
      src = call (import ./askuserquestion.nix);
      # Whole repo is the extension (src/, package.json at root)
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

    # hashline-edit = {
    #   src = withRuntimeDeps {
    #     src = pkgs.runCommand "pi-hashline-edit-with-lock" {} ''
    #       mkdir -p $out
    #       cp -R ${call (import ./hashline-edit.nix)}/. $out/
    #       chmod -R u+w $out
    #       ${pkgs.nodejs_22}/bin/node -e "
    #         const fs = require('fs');
    #         const path = '$out/package.json';
    #         const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
    #         delete pkg.peerDependencies;
    #         delete pkg.devDependencies;
    #         fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
    #       "
    #       cp ${./hashline-edit-package-lock.json} $out/package-lock.json
    #     '';
    #     npmDepsHash = "sha256-XYZOgMNRTpTWkrWwF6xWCJEBv1Aq+O2n/A6R7rn59rc=";
    #   };
    #   # Whole repo is the extension (src/, package.json at root)
    #   resources.extensions = ".";
    # };

    tasks = {
      src = withRuntimeDeps {
        src = call (import ./tasks.nix);
        npmDepsHash = "sha256-BU8Xni+K/+nk2FmK8FkWCg4iGG5PWR9FFLkckfd356c=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    subagents = {
      src = withRuntimeDeps {
        src = pkgs.runCommand "pi-subagents-safe-defaults" {} ''
          mkdir -p $out
          cp -R ${call (import ./subagents.nix)}/. $out/
          chmod -R u+w $out
          ${pkgs.nodejs_22}/bin/node -e '
            const fs = require("fs");
            const scopeFile = process.env.out + "/agent-scope.ts";
            const scopeSource = fs.readFileSync(scopeFile, "utf8");
            const scoped = scopeSource.replace("return \"both\";", "return \"user\";");
            if (scopeSource === scoped) throw new Error("Failed to patch default subagent scope");
            fs.writeFileSync(scopeFile, scoped);

            const typesFile = process.env.out + "/types.ts";
            const typesSource = fs.readFileSync(typesFile, "utf8");
            const tempPattern = /export const TEMP_ROOT_DIR = path\.join\(os\.tmpdir\(\), `pi-subagents-[^`]+`\);/;
            const tempNew = "export const TEMP_ROOT_DIR = path.join(os.homedir(), \".cache\", \"pi-subagents\", resolveTempScopeId());";
            const patchedTypes = typesSource.replace(tempPattern, tempNew);
            if (typesSource === patchedTypes) throw new Error("Failed to patch subagent temp directory");
            fs.writeFileSync(typesFile, patchedTypes);
          '
        '';
        npmDepsHash = "sha256-zylxs17WVNYRf3JsFUvibA1ix5JqP5iOLOkns8f0Lis=";
      };
      # Whole repo is the extension (src/, package.json at root)
      resources.extensions = ".";
    };

    guardrails = {
      src = withRuntimeDeps {
        src = pkgs.runCommand "pi-guardrails-strict-permission-gate" {} ''
          mkdir -p $out
          cp -R ${call (import ./guardrails.nix)}/. $out/
          chmod -R u+w $out
          ${pkgs.nodejs_22}/bin/node -e '
            const fs = require("fs");
            const file = process.env.out + "/src/hooks/permission-gate/index.ts";
            const lines = fs.readFileSync(file, "utf8").split("\n");
            const start = lines.findIndex((line, index) =>
              line.trim() === "if (" &&
              lines[index + 1]?.trim() === "useBuiltinMatchers &&" &&
              lines[index + 2]?.trim() === "parsedSuccessfully &&" &&
              lines[index + 3]?.trim() === "!src.regex &&" &&
              lines[index + 4]?.trim() === "BUILTIN_KEYWORD_PATTERNS.has(src.pattern)"
            );
            if (start === -1) throw new Error("Failed to patch guardrails permission gate");
            lines.splice(start, 9);
            fs.writeFileSync(file, lines.join("\n"));
          '
        '';
        pnpmDepsHash = "sha256-H7rhxjbROpIm6gAJCAXDP21Q9WZ+EMclECBiOZJofZs=";
      };
      resources.extensions = ".";
    };

    # toolchain = {
    #   src = withRuntimeDeps {
    #     src = call (import ./toolchain.nix);
    #     pnpmDepsHash = "sha256-pug/Ws9rL9wwWZbTYfyDtJZDX70/0XgT7EEcO+1b7s8=";
    #   };
    #   resources.extensions = ".";
    # };

    # processes = {
    #   src = withRuntimeDeps {
    #     src = call (import ./processes.nix);
    #     pnpmDepsHash = "sha256-oX8+q3eeCVLAYMztIzsrlvK1LAp8ifMF+jnfc94RhCs=";
    #   };
    #   resources.extensions = ".";
    # };

    # "pi-ptc" = {
    #   src = withRuntimeDeps {
    #     src = call (import ./pi-ptc.nix);
    #     npmDepsHash = "sha256-5qnicFVwaHGgM+yVTrRtwwMC2RF7huX66o8+XFWsc64=";
    #   };
    #   resources.extensions = ".";
    # };

    # "pi-memory" = {
    #   src = withRuntimeDeps {
    #     src = pkgs.runCommand "pi-memory-extension-src" {} ''
    #       mkdir -p $out
    #       cp -R ${call (import ./pi-memory.nix)}/extensions/pi-memory/. $out/
    #     '';
    #     npmDepsHash = "sha256-MoFbg8vpEmwAx1o9vzqut2VNEts22pqaOpsLYE/MnZ8=";
    #   };
    #   resources.extensions = ".";
    #   resources.skills = "skills";
    # };

    "context-guard" = {
      src = pkgs.runCommand "pi-context-guard-src" {} ''
        mkdir -p $out
        cp -R ${call (import ./context-guard.nix)}/extensions/context-guard/. $out/
      '';
      resources.extensions = ".";
    };

    "pi-pane" = {
      src = call (import ./pi-pane.nix);
      resources.extensions = ".";
    };

    # "pi-fff" = {
    #   src = withRuntimeDeps {
    #     src = pkgs.runCommand "pi-fff-with-lock" {} ''
    #       mkdir -p $out
    #       cp -R ${call (import ./pi-fff.nix)}/. $out/
    #       chmod -R u+w $out
    #       ${pkgs.nodejs_22}/bin/node -e "
    #         const fs = require('fs');
    #         const path = '$out/package.json';
    #         const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
    #         delete pkg.peerDependencies;
    #         delete pkg.devDependencies;
    #         fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
    #       "
    #       cp ${./pi-fff-package-lock.json} $out/package-lock.json
    #     '';
    #     npmDepsHash = "sha256-NAIOKRHXr9YZYQq03wMF7UxZd3Y1HNBBhexEWW/3tcM=";
    #   };
    #   resources.extensions = ".";
    # };

    # "pi-mouse" = {
    #   src = pkgs.runCommand "pi-mouse-src" {} ''
    #     mkdir -p $out
    #     cp -R ${call (import ./pi-mouse.nix)}/packages/pi-mouse/. $out/
    #   '';
    #   resources.extensions = "extensions";
    # };

    "pi-subdir-context" = {
      src = pkgs.runCommand "pi-subdir-context-safe-src" {} ''
        mkdir -p $out
        cp -R ${call (import ./pi-subdir-context.nix)}/. $out/
        chmod -R u+w $out
        ${pkgs.nodejs_22}/bin/node -e '
          const fs = require("fs");
          const file = process.env.out + "/src/index.ts";
          const source = fs.readFileSync(file, "utf8");
          const start = source.indexOf("\tfunction getAgentsFileFromDir");
          const end = source.indexOf("\n\tfunction resetSession", start);
          if (start === -1 || end === -1) throw new Error("Failed to patch pi-subdir-context symlink handling");
          const replacement = [
            "\tfunction getAgentsFileFromDir(dir: string) {",
            "\t\tconst realDir = resolvePath(dir, process.cwd());",
            "",
            "\t\tfor (const filename of AGENTS_FILENAMES) {",
            "\t\t\tconst candidate = path.join(dir, filename);",
            "\t\t\tif (!fs.existsSync(candidate)) continue;",
            "",
            "\t\t\tconst realCandidate = resolvePath(candidate, dir);",
            "\t\t\tif (isInsideRoot(realDir, realCandidate)) return realCandidate;",
            "\t\t}",
            "",
            "\t\treturn \"\";",
            "\t}",
          ].join("\n");
          fs.writeFileSync(file, source.slice(0, start) + replacement + source.slice(end));
        '
      '';
      resources.extensions = ".";
    };

    # "pi-curated-themes" = {
    #   src = call (import ./pi-curated-themes.nix);
    #   resources.themes = "themes";
    # };

    # "pi-diff-review" = {
    #   src = withRuntimeDeps {
    #     src = call (import ./pi-diff-review.nix);
    #     npmDepsHash = "sha256-4BeJ4Tjjpk30xBs/GZ4J3+w3WRHNTAfRk75VUf8Ee3U=";
    #   };
    #   resources.extensions = ".";
    # };

    "pi-verbosity-control" = {
      src = call (import ./pi-verbosity-control.nix);
      resources.extensions = ".";
    };

    "pi-claude-bridge" = {
      src = withRuntimeDeps {
        src = pkgs.callPackage ./pi-claude-bridge.nix {};
        npmDepsHash = "sha256-oPDGO37dgBi6/SDPp+wtbra1k3e8YJJVPuiq+++MrPs=";
      };
      resources.extensions = ".";
    };

    "pi-codex-fast" = {
      src = pkgs.runCommand "pi-codex-fast-src" {} ''
        mkdir -p $out
        cp ${call (import ./pi-codex-fast.nix)}/extensions/codex-fast.ts $out/index.ts
      '';
      resources.extensions = ".";
    };

    # "pi-codex-conversion" = {
    #   src = withRuntimeDeps {
    #     src = call (import ./pi-codex-conversion.nix);
    #     npmDepsHash = "sha256-pZEujjYmjfW8dEp6AQIvKJcMJGWdqHkLONFVWXc9/po=";
    #   };
    #   resources.extensions = ".";
    # };

    "pi-token-usage" = {
      src = withRuntimeDeps {
        src = pkgs.runCommand "pi-token-usage-src" {} ''
          mkdir -p $out
          cd $out
          tar xzf ${pkgs.fetchurl (import ./pi-token-usage.nix)} --strip-components=1
          ${pkgs.nodejs_22}/bin/node -e "
            const fs = require('fs');
            const path = '$out/package.json';
            const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
            delete pkg.peerDependencies;
            delete pkg.devDependencies;
            fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
          "
          cp ${./pi-token-usage-package-lock.json} $out/package-lock.json
        '';
        npmDepsHash = "sha256-ik73E3J97G+r6fN529P9+G5Mw9gsZTsdGH74KeYJqhw=";
      };
      resources.extensions = ".";
    };

    "pi-vcc" = {
      src = pkgs.runCommand "pi-vcc-src" {} ''
        mkdir -p $out
        cp -R ${call (import ./pi-vcc.nix)}/. $out/
        chmod -R u+w $out
        substituteInPlace $out/src/tools/recall.ts \
          --replace-fail '"@sinclair/typebox"' '"typebox"'
      '';
      resources.extensions = ".";
    };

    # "pi-better-messages-cache" = {
    #   src = withRuntimeDeps {
    #     src = pkgs.runCommand "pi-better-messages-cache-src" {} ''
    #       mkdir -p $out
    #       cp -R ${call (import ./pi-better-messages-cache.nix)}/. $out/
    #       chmod -R u+w $out
    #       ${pkgs.nodejs_22}/bin/node -e "
    #         const fs = require('fs');
    #         const path = '$out/package.json';
    #         const pkg = JSON.parse(fs.readFileSync(path, 'utf8'));
    #         delete pkg.peerDependencies;
    #         delete pkg.devDependencies;
    #         fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
    #       "
    #     '';
    #     npmDepsHash = "sha256-BSm67qBoeendegdcpQeQMJs7kNlc9MISbkQBJfq2Low=";
    #   };
    #   resources.extensions = ".";
    # };

    # Custom local extensions (no fetching needed)
    # tab-queue = {
    #   src = ./custom/tab-queue;
    #   resources.extensions = ".";
    # };

    escape-steer = {
      src = ./custom/escape-steer;
      resources.extensions = ".";
    };

    effort = {
      src = ./custom/effort;
      resources.extensions = ".";
    };

    theme = {
      src = ./custom/theme;
      resources.extensions = ".";
    };

    notify = {
      src = ./custom/notify;
      resources.extensions = ".";
    };

    dump-system-prompt = {
      src = ./custom/dump-system-prompt;
      resources.extensions = ".";
    };

    session-handoff = {
      src = ./custom/session-handoff;
      resources.extensions = ".";
    };

    # cache-countdown = {
    #   src = ./custom/cache-countdown;
    #   resources.extensions = ".";
    # };
  }
  // agentStuff
