{
  buildNpmPackage,
  fetchzip,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-web-providers";
  version = "3.0.0";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-hHO50KvRH34cimmCLizlMzAL3JX0TiEvhpxYGlKLVvk=";
  };

  npmDepsHash = "sha256-N/uvIU4OhoTIFADUS4851MnYq7F5AxObirmqdiP12qw=";

  postPatch = ''
    cp ${./pi-web-providers-package-lock.json} package-lock.json
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
