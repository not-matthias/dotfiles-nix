{
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-amplike";
  version = "1.3.4";

  nodejs = nodejs_22;

  src = fetchFromGitHub {
    owner = "pasky";
    repo = "pi-amplike";
    rev = "v1.3.4";
    hash = "sha256-onMnOm8hU08U3ms6JK7tlOD7wYXLtu05RYng3pS0orY=";
  };

  npmDepsHash = "sha256-mTjzYIBXEFbuC4aWrXU8QolcL4kSW0E4eMfUQAHS4FA=";

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
