{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-anthropic-oauth";
  version = "0.3.1";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "leohenon";
    repo = "pi-anthropic-oauth";
    rev = "22db92c832d3e9962fd1c73355b6dfd2975d60cd";
    hash = "sha256-tu8T2x/N9qf5nuV5x4qWiKfYcBrsD1WDFqfEVbWKmSo=";
  };

  npmDepsHash = "sha256-C//zv32vaTBaJygcPChU/eWfpTZ7L6mFW4yMEd0r4Pk=";

  postPatch = ''
    cp ${./pi-anthropic-oauth-package-lock.json} package-lock.json
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

  meta = {
    description = "Anthropic OAuth extension for pi — authenticate with your Anthropic account";
    homepage = "https://github.com/leohenon/pi-anthropic-oauth";
    license.spdxId = "MIT";
  };
}
