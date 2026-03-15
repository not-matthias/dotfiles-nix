{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage rec {
  pname = "pi-coding-agent";
  version = "0.58.1";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-sn0wXaKEd6Ez/wKPqxtoBJA9xOyWvWKXqYMTZMI9uOQ=";
  };

  npmDepsHash = "sha256-q608ZbQVeJwzAFsaMsepY10GUh4It99SO2qpDagp2OM=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    # Remove devDependencies so npm doesn't try to fetch them
    ${nodejs}/bin/node -e "
      const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
      delete pkg.devDependencies;
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "
  '';

  dontNpmBuild = true;
  npmInstallFlags = ["--omit=dev"];

  nativeBuildInputs = [makeWrapper];

  postInstall = ''
    wrapProgram $out/bin/pi \
      --set PI_SKIP_VERSION_CHECK 1
  '';

  meta = {
    description = "Minimal terminal coding harness - extensible with TypeScript extensions, skills, and prompt templates";
    homepage = "https://github.com/badlogic/pi-mono";
    downloadPage = "https://www.npmjs.com/package/@mariozechner/pi-coding-agent";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "pi";
  };
}
