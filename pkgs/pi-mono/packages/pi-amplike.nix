{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-amplike";
  version = "1.3.3";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "pasky";
    repo = "pi-amplike";
    rev = "7fbf6fb60cda5e9610929bfebf923b5034b80eb0";
    hash = "sha256-AAQwkwc09dvV538IiscP2izRqI+/h/UKVvEfD0H57+o=";
  };

  npmDepsHash = "sha256-BCE1G9P9c17Vpdmfi64t6iYcXYcld9btAHqJAoziT0E=";

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
