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
  version = "0.21.3";
  src = fetchFromGitHub {
    owner = "steipete";
    repo = "oracle";
    tag = "v${version}";
    hash = "sha256-tlkKKtmrEHcCKRBrFC6LzQgqab7wk+25MEgwz8pu4b4=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;
    patches = [
      ./oracle-chatgpt-turns.patch
      ./oracle-model-picker.patch
    ];

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-W5ztl3Ks5mvIT8ykm4H6ENtss+6Ad23n8FUdGVmw21c=";
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
