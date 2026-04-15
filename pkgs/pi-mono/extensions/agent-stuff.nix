{pkgs}: let
  src = pkgs.fetchFromGitHub {
    owner = "mitsuhiko";
    repo = "agent-stuff";
    rev = "2b70e8d53647c1e0277bd54dbbb2519cb5bea92b";
    hash = "sha256-1bsuBvCWNsmV0r4+fU66oHWFu9MXKchuH/GRMnb7QxQ=";
  };

  mkWrappedExtension = {
    name,
    entry,
    prePackageJson ? "",
  }: {
    src = pkgs.runCommand "${name}-extension" {} ''
      mkdir -p $out
      cp ${src}/extensions/${entry}.ts $out/index.ts
      chmod +w $out/index.ts
      ${prePackageJson}
      cat >$out/package.json <<'EOF'
      {"name":"${name}","private":true,"type":"module"}
      EOF
    '';
    resources.extensions = ".";
  };
in {
  # Shared non-extension resources from the upstream repo.
  # Intentionally do not expose upstream agent-stuff skills.
  agent-stuff = {
    inherit src;
    resources.themes = "pi-themes";
    resources.prompts = "commands";
  };

  # Separate packages so pi discovers each extension as its own path.
  agent-stuff-context = mkWrappedExtension {
    name = "agent-stuff-context";
    entry = "context";
  };

  agent-stuff-session-breakdown = mkWrappedExtension {
    name = "agent-stuff-session-breakdown";
    entry = "session-breakdown";
  };

  agent-stuff-multi-edit = {
    src = pkgs.callPackage ./with-runtime-deps.nix {
      src = pkgs.runCommand "agent-stuff-multi-edit-src" {} ''
        mkdir -p $out
        cp ${src}/extensions/multi-edit.ts $out/index.ts
        chmod +w $out/index.ts
        ${pkgs.nodejs_22}/bin/node -e "
          const fs = require('fs');
          const p = '$out/index.ts';
          const s = fs.readFileSync(p, 'utf8');
          fs.writeFileSync(
            p,
            s.replace('name: \"edit\"', 'name: \"multi-edit\"').replace('label: \"edit\"', 'label: \"multi-edit\"')
          );
        "
        cat >$out/package.json <<'EOF'
        {"name":"agent-stuff-multi-edit","private":true,"type":"module","dependencies":{"diff":"^7.0.0"}}
        EOF
        cp ${./multi-edit-package-lock.json} $out/package-lock.json
      '';
      npmDepsHash = "sha256-SNWeJcipUnwQhUAuf1ugCaGlNuKJRAQTEwW4qZfMu+s=";
    };
    resources.extensions = ".";
  };
}
