{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-diff";
  version = "0.1.6";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-diff";
    rev = "fbb209e1bc27054b3e21a76fa3af24f5570d7845";
    hash = "sha256-LDqMKl5ErwFOBVd+Q7xPgaU4C0oXVL+l/XypQXnknu4=";
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
