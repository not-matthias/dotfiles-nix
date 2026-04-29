{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-anthropic-oauth";
  version = "0.1.11";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "leohenon";
    repo = "pi-anthropic-oauth";
    rev = "a85010c51e0185a9f565460fa370e8b96b97597b";
    hash = "sha256-pn5zd6pySMpJbsVz4NyujZ+25zd0GFblYY/ujNTDSh8=";
  };

  npmDepsHash = "sha256-Cv9mAdaAYWAIOH6W5LkIL3QrWr8PggIuuU3DfNoMqWk=";

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
