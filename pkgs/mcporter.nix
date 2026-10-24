{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  npmHooks,
  versionCheckHook,
  nix-update-script,
}: let
  pname = "mcporter";
  version = "0.16.0";
  pnpm = pnpm_10;
  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "mcporter";
    rev = "9a8ed529e313f452a0ce977894cb63c4620ddd7c";
    hash = "sha256-ns5QsyLStBUIO6ove55CZFPbUFHsKKdBSUP+dXWWjCo=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-iVP46rt0bx/cWvnQblBnhgM1wvOe69ce7JHGPNNiilg=";
    };

    nativeBuildInputs = [
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

    nativeInstallCheckInputs = [
      versionCheckHook
    ];

    doInstallCheck = true;

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "TypeScript runtime and CLI for connecting to configured Model Context Protocol servers";
      homepage = "https://github.com/openclaw/mcporter";
      changelog = "https://github.com/openclaw/mcporter/releases/tag/v${version}";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [mkg20001];
      mainProgram = "mcporter";
    };
  }
