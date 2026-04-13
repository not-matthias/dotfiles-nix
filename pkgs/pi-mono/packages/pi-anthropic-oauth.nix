{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-anthropic-oauth";
  version = "0.1.5";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "leohenon";
    repo = "pi-anthropic-oauth";
    rev = "1f8bb8bdabdf00b4b8d936d27e217d4ad74308e3";
    hash = "sha256-XJe3GVykKnVc8dWAYe29CdQEdyejcgiLSTts2hcbjzo=";
  };

  npmDepsHash = "sha256-zXm3p/YOo8pEF7e80Ne67o8yCgzP/t6Vart6w5nWyKM=";

  postPatch = ''
    cp ${./pi-anthropic-oauth-package-lock.json} package-lock.json
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
    description = "Anthropic OAuth extension for pi — authenticate with your Anthropic account";
    homepage = "https://github.com/leohenon/pi-anthropic-oauth";
    license.spdxId = "MIT";
  };
}
