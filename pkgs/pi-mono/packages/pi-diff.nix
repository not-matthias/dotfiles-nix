{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-diff";
  version = "0.1.5";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-diff";
    rev = "055ed8a423515ecbd506b486962835fa13f9fb7c";
    hash = "sha256-m7+VDveMbPZeeT9D2EJ/jU1Kld2lDuL7yzWE5iTBOHE=";
  };

  npmDepsHash = "sha256-JuonDFNrq3bWJZEXJAXOM1VEW+5c1/W6KQC5O8adn3o=";

  postPatch = ''
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
}
