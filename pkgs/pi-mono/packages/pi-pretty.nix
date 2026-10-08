{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-pretty";
  version = "0.6.31";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-pretty";
    rev = "a8062beae2de6337b34ca8a17721caeb086ba5b8";
    hash = "sha256-HTGjUHDw+Myk/B5BT5Qa8ZG9NCOLeugvhu3uIYQtb/4=";
  };

  npmDepsHash = "sha256-Y/HHWykn+RDJW+ugDLmmc5M2sRy+GQOPF9iB5jjaBJI=";

  postPatch = ''
    cp ${./pi-pretty-package-lock.json} package-lock.json
    ${nodejs_22}/bin/node -e "
      const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
      delete pkg.devDependencies;
      delete pkg.peerDependencies;
      require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
    "
  '';

  dontNpmBuild = true;
  npmInstallFlags = ["--omit=dev" "--omit=peer" "--ignore-scripts"];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R . $out/
    runHook postInstall
  '';
}
