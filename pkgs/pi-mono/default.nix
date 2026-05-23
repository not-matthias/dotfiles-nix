{
  lib,
  buildNpmPackage,
  fetchzip,
  fetchNpmDeps,
  runCommand,
  nodejs_22,
  makeWrapper,
}: let
  rawSrc = fetchzip {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-0.75.5.tgz";
    hash = "sha256-oZIzs+txiowbC1wkb3u8yIsXj/RU8snrlsWX8q2zq84=";
  };
  patchedSrc = runCommand "pi-coding-agent-src" {} ''
    cp -r ${rawSrc} $out
    chmod -R +w $out
    cp ${./package-lock.json} $out/package-lock.json
    rm -f $out/npm-shrinkwrap.json
  '';
in
  buildNpmPackage rec {
    pname = "pi-coding-agent";
    version = "0.75.5";

    nodejs = nodejs_22;

    src = patchedSrc;

    npmDeps = fetchNpmDeps {
      inherit src;
      name = "${pname}-${version}-npm-deps";
      hash = "sha256-+pgQBAsylGdY1IAXbqdCmxTrTyWCk6q9KoMN70yI6FU=";
    };

    postPatch = ''
      ${nodejs}/bin/node -e "
        const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
        delete pkg.devDependencies;
        require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
      "
    '';

    dontNpmBuild = true;
    npmInstallFlags = ["--omit=dev"];

    nativeBuildInputs = [makeWrapper];

    postInstall = ''
      wrapProgram $out/bin/pi \
        --set PI_SKIP_VERSION_CHECK 1 \
        --run 'export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"' \
        --run 'export PATH="''${NPM_CONFIG_PREFIX:-$HOME/.npm-global}/bin:$PATH"'
    '';

    meta = {
      description = "Minimal terminal coding harness - extensible with TypeScript extensions, skills, and prompt templates";
      homepage = "https://github.com/badlogic/pi-mono";
      downloadPage = "https://www.npmjs.com/package/@mariozechner/pi-coding-agent";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "pi";
    };
  }
