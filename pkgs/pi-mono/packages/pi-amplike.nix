{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-amplike";
  version = "1.3.2";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "pasky";
    repo = "pi-amplike";
    rev = "d28294026ba13e5c4eb21a227c6af1478d95ddc4";
    hash = "sha256-xEIbNjHpP3pDmQ6wY1AvMBzkGXWsHax580LcedCRg54=";
  };

  npmDepsHash = "sha256-blKzjY9YyeOmiqoYgLDMpbiJ/FP003TFy4flbf1kqGQ=";

  postPatch = ''
    cp ${./pi-amplike-package-lock.json} package-lock.json
    ${nodejs_22}/bin/node -e "
      const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
      delete pkg.devDependencies;
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "
  '';

  dontNpmBuild = true;
  npmInstallFlags = ["--omit=dev" "--ignore-scripts"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';

  meta = {
    description = "Pi skills and extensions that provide Amp Code-like workflows (handoff, permissions, mode selector, web access)";
    homepage = "https://github.com/pasky/pi-amplike";
    license.spdxId = "MIT";
  };
}
