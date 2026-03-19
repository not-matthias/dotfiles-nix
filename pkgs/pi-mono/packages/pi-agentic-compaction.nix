{
  buildNpmPackage,
  fetchzip,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-agentic-compaction";
  version = "0.3.0";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-Ayhc/rE1CzXeo+g1t+6OoYMwDVUSV01MDVcs88Uytc4=";
  };

  npmDepsHash = "sha256-jwA4yaWq+Nvn5JLPqEmnmbse4Aeqoq7YXZOJNW0lV+U=";

  postPatch = ''
    cp ${./pi-agentic-compaction-package-lock.json} package-lock.json
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
