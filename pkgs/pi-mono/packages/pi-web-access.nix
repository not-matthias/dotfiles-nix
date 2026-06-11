{
  buildNpmPackage,
  fetchzip,
  fetchNpmDeps,
  runCommand,
  nodejs_22,
}: let
  pname = "pi-web-access";
  version = "0.10.7";

  rawSrc = fetchzip {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-KQykDba+Bw4/BzJUv5pW3Ha4CSFb3AyQ+on7bRXZj2U=";
  };

  patchedSrc = runCommand "${pname}-src" {} ''
    cp -r ${rawSrc} $out
    chmod -R +w $out
    cp ${./pi-web-access-package-lock.json} $out/package-lock.json
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
    ${nodejs_22}/bin/node <<'EOF'
      const fs = require('fs');
      const file = process.env.out + '/github-extract.ts';
      let source = fs.readFileSync(file, 'utf8');

      source = source.replace(
        'const NON_CODE_SEGMENTS = new Set([',
        'function isSafeGitHubSegment(segment) {\n' +
        '  return /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/.test(segment) && !segment.includes("..");\n' +
        '}\n\n' +
        'const NON_CODE_SEGMENTS = new Set(['
      );

      source = source.replace(
        'const owner = segments[0];\n\tconst repo = segments[1].replace(/\\.git$/, "");',
        'const owner = segments[0];\n\tconst repo = segments[1].replace(/\\.git$/, "");\n\tif (!isSafeGitHubSegment(owner) || !isSafeGitHubSegment(repo)) return null;'
      );

      source = source.replace(
        'const ref = segments[3];\n\tconst refIsFullSha = /^[0-9a-f]{40}$/.test(ref);',
        'const ref = segments[3];\n\tif (!isSafeGitHubSegment(ref)) return null;\n\tconst refIsFullSha = /^[0-9a-f]{40}$/.test(ref);'
      );

      fs.writeFileSync(file, source);
    EOF
  '';
in
  buildNpmPackage {
    inherit pname version;

    nodejs = nodejs_22;
    src = patchedSrc;

    npmDeps = fetchNpmDeps {
      name = "${pname}-${version}-npm-deps";
      src = patchedSrc;
      hash = "sha256-p+pLopNZ+8H3so2iZ0Rtrn1ndt61Vp1uChGGjUuPrWY=";
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
