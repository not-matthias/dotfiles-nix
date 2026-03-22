{pkgs}: let
  src = pkgs.fetchFromGitHub {
    owner = "mitsuhiko";
    repo = "agent-stuff";
    rev = "f0f29f95a03a3d4e00b6aaefabcef702e81c1719";
    hash = "sha256-pqGu+lTpqwp98Xckb6yRDEDiB4Gz+f6c15zxmT8Fv2U=";
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
