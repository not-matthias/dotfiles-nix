{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  python3,
  sqlite,
  makeWrapper,
  nodejs,
}: let
  pname = "qmd";
  version = "2.8.3";
in
  buildNpmPackage {
    inherit pname version;

    src = fetchFromGitHub {
      owner = "tobi";
      repo = "qmd";
      tag = "v${version}";
      hash = "sha256-/7Z94r/9rXqzKlz/YkB6/nToSCPamV4Dnxm8EhelTDo=";
    };

    postPatch = ''
      cp ${./qmd-package-lock.json} package-lock.json
    '';

    npmDepsHash = "sha256-mCuFb7PCUydRMJHkwVnZv+fVtCYBQ9+t3q9t/gCd9mU=";

    nativeBuildInputs = [python3 makeWrapper nodejs];
    buildInputs = [sqlite];

    # Build TypeScript source to dist/
    npmBuildScript = "build";

    # The upstream bin/qmd is a shell script that detects node vs bun.
    # The default npm wrapper tries to run it through node, which fails.
    # Replace with a proper wrapper pointing to dist/cli/qmd.js directly.
    postInstall = ''
      rm $out/bin/qmd
      makeWrapper ${nodejs}/bin/node $out/bin/qmd \
        --add-flags "$out/lib/node_modules/@tobilu/qmd/dist/cli/qmd.js"
    '';

    meta = {
      description = "On-device hybrid search for markdown files with BM25, vector search, and LLM reranking";
      homepage = "https://github.com/tobi/qmd";
      license = lib.licenses.mit;
      mainProgram = "qmd";
      platforms = lib.platforms.linux;
    };
  }
