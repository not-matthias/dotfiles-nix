{
  lib,
  buildNpmPackage,
  fetchzip,
  nodejs_22,
  makeWrapper,
}:
buildNpmPackage rec {
  pname = "pi-coding-agent";
  version = "0.70.2";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-XLBqNftsichY77v7DysuZTNILMDWmteGilEB3w3fy0o=";
  };

  npmDepsHash = "sha256-bG1Hg8sH8kY0IEkL2CWdscrVLMVL6PDfDkTS5RviPDg=";

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
      --set PI_SKIP_VERSION_CHECK 1 \
      --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"' \
      --run 'export PATH="''${NPM_CONFIG_PREFIX:-$HOME/.npm-global}/bin:$PATH"'
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
