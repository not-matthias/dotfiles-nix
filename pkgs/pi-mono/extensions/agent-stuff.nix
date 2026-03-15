{pkgs}: let
  src = pkgs.fetchFromGitHub {
    owner = "mitsuhiko";
    repo = "agent-stuff";
    rev = "2f10121503260d694f5626d4d7039591a6f2c75f";
    hash = "sha256-4XCG1uxMij68iQPGubvFm3q/rm2n9d30dU7LmuU7eJ0=";
  };

  mkWrappedExtension = {
    name,
    entry,
    prePackageJson ? "",
  }: {
    src = pkgs.runCommand "${name}-extension" {} ''
      mkdir -p $out
      cp ${src}/pi-extensions/${entry}.ts $out/index.ts
      ${prePackageJson}
      cat >$out/package.json <<'EOF'
      {"name":"${name}","private":true,"type":"module"}
      EOF
    '';
    resources.extensions = ".";
  };

  filteredSkills = pkgs.runCommand "agent-stuff-skills" {} ''
    cp -r ${src}/skills $out
    chmod -R u+w $out
    rm -rf $out/commit $out/github $out/mermaid $out/uv
  '';
in {
  # Shared non-extension resources from the upstream repo.
  agent-stuff = {
    inherit src;
    resources.themes = "pi-themes";
    resources.skills = filteredSkills;
    resources.prompts = "commands";
    skillsAbsolute = true;
  };

  # Separate packages so pi discovers each extension as its own path.
  agent-stuff-answer = mkWrappedExtension {
    name = "agent-stuff-answer";
    entry = "answer";
  };

  agent-stuff-context = mkWrappedExtension {
    name = "agent-stuff-context";
    entry = "context";
  };

  agent-stuff-multi-edit = mkWrappedExtension {
    name = "agent-stuff-multi-edit";
    entry = "multi-edit";
    prePackageJson = ''
      mkdir -p $out/node_modules
      # multi-edit imports "diff"; copy it locally so extension resolution works.
      cp -r ${pkgs.pi-coding-agent}/lib/node_modules/@mariozechner/pi-coding-agent/node_modules/diff $out/node_modules/diff
    '';
  };

  agent-stuff-notify = mkWrappedExtension {
    name = "agent-stuff-notify";
    entry = "notify";
  };

  agent-stuff-session-breakdown = mkWrappedExtension {
    name = "agent-stuff-session-breakdown";
    entry = "session-breakdown";
  };

  agent-stuff-todos = mkWrappedExtension {
    name = "agent-stuff-todos";
    entry = "todos";
  };

  agent-stuff-uv = mkWrappedExtension {
    name = "agent-stuff-uv";
    entry = "uv";
  };
}
