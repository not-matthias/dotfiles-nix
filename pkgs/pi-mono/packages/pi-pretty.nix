{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-pretty";
  version = "0.1.8";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-pretty";
    rev = "e91a6a68b6734e35e64319d5689e4152a26fdd1f";
    hash = "sha256-0yV8c+X8x8PbpqNJaZwu2ABVGarXR5234jRUHjUn++A=";
  };

  npmDepsHash = "sha256-NwKsfX1ntb3IXBgDqe1zQOfU4Vh6YUlvaU6C7D1X01g=";

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
