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
in {
  # Shared non-extension resources from the upstream repo.
  # Intentionally do not expose upstream agent-stuff skills.
  agent-stuff = {
    inherit src;
    resources.themes = "pi-themes";
    resources.prompts = "commands";
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

  agent-stuff-notify = mkWrappedExtension {
    name = "agent-stuff-notify";
    entry = "notify";
  };

  agent-stuff-session-breakdown = mkWrappedExtension {
    name = "agent-stuff-session-breakdown";
    entry = "session-breakdown";
  };

  agent-stuff-uv = mkWrappedExtension {
    name = "agent-stuff-uv";
    entry = "uv";
  };
}
