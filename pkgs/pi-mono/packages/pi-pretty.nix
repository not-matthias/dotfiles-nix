{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-pretty";
  version = "0.4.2";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-pretty";
    rev = "7f446128c17fb59f46463d55008e504c84712f0b";
    hash = "sha256-EnCsL/0U0h0zJJtXFcQr91GPxl0K7rl4l477wJCg8PE=";
  };

  npmDepsHash = "sha256-ppdECsYTLu5bxN+kJltjD+ukS5hAjmeKhDKEAH8bmoU=";

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
