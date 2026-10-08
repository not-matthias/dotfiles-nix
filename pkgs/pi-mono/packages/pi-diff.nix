{
  buildNpmPackage,
  fetchzip,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "pi-diff";
  version = "0.9.2";

  nodejs = nodejs_22;

  src = fetchzip {
    url = "https://registry.npmjs.org/@heyhuynhgiabuu/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-RxmzzWmFlcyUsox7b/Mj/VRJJgA7dcvn99iSpKm7ZN8=";
  };

  npmDepsHash = "sha256-YNDPxCxUJ8GDWafcYNMNVxPstI5UWxR8UEX9jpIXzZU=";

  postPatch = ''
    cp ${./pi-diff-package-lock.json} package-lock.json
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
}
