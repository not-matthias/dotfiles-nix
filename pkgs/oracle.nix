{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm,
  npmHooks,
  versionCheckHook,
  nix-update-script,
  makeWrapper,
}: let
  pname = "oracle";
  version = "0.21.2";
  src = fetchFromGitHub {
    owner = "steipete";
    repo = "oracle";
    tag = "v${version}";
    hash = "sha256-uyH6LV02ZhN1M8adV3eIOoz8NB1cMBn9g+O1rdACX0Q=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-DmpnfNIETr9Ud6PzSLHg3M21v274Q2PGeKLW7SvGW80=";
    };

    nativeBuildInputs = [
      makeWrapper
      nodejs
      pnpmConfigHook
      pnpm
      npmHooks.npmInstallHook
    ];

    buildPhase = ''
      runHook preBuild
      pnpm run build
      runHook postBuild
    '';

    dontNpmPrune = true;

    postInstall = ''
      rm -f $out/bin/oracle $out/bin/oracle-mcp
      makeWrapper ${nodejs}/bin/node $out/bin/oracle \
        --add-flags "$out/lib/node_modules/@steipete/oracle/dist/bin/oracle-cli.js"
      makeWrapper ${nodejs}/bin/node $out/bin/oracle-mcp \
        --add-flags "$out/lib/node_modules/@steipete/oracle/dist/bin/oracle-mcp.js"
    '';

    nativeInstallCheckInputs = [versionCheckHook];
    doInstallCheck = true;

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "CLI and MCP server for grounded second-model consultations";
      homepage = "https://askoracle.sh";
      changelog = "https://github.com/steipete/oracle/releases/tag/v${version}";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "oracle";
    };
  }
