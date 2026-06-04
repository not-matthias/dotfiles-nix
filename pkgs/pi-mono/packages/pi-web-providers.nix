{
  buildNpmPackage,
  fetchzip,
  fetchNpmDeps,
  runCommand,
  nodejs_22,
}: let
  pname = "pi-web-providers";
  version = "3.3.0";

  rawSrc = fetchzip {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-rcX/68DRFxol7UmRpy9XgfNJYLm7F2fJ36NfwTYKgvk=";
  };

  patchedSrc = runCommand "${pname}-src" {} ''
    cp -r ${rawSrc} $out
    chmod -R +w $out
    cp ${./pi-web-providers-package-lock.json} $out/package-lock.json
    ${nodejs_22}/bin/node -e "
      const pkg = JSON.parse(require('fs').readFileSync('$out/package.json', 'utf8'));
      delete pkg.devDependencies;
      delete pkg.peerDependencies;
      delete pkg.engines;
      for (const k of Object.keys(pkg.dependencies || {})) {
        if (k.startsWith('@earendil-works/') || k.startsWith('@mariozechner/')) delete pkg.dependencies[k];
      }
      require('fs').writeFileSync('$out/package.json', JSON.stringify(pkg, null, 2));
    "
  '';
in
  buildNpmPackage {
    inherit pname version;

    nodejs = nodejs_22;
    src = patchedSrc;

    npmDeps = fetchNpmDeps {
      name = "${pname}-${version}-npm-deps";
      src = patchedSrc;
      hash = "sha256-p4ehGpbdBpbYkYPwqPtT8W4fQA459FptYMrMlaL0PVM=";
    };

    dontNpmBuild = true;
    npmInstallFlags = ["--omit=dev" "--omit=peer" "--ignore-scripts"];

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R . $out/
      runHook postInstall
    '';
  }
