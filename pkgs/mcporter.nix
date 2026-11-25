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
  version = "0.17.1";
  pnpm = pnpm_10;
  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "mcporter";
    rev = "0d8ccc9e92e9dc66875f998730485dea1a0801f4";
    hash = "sha256-iocO27hi4q23pOpYql70qO8OTWTTDGDkEaVm/Q8AYwA=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-cusO172/2xDB4LR93Eag+PWJUAaT5Cgx5eI+KXFgccw=";
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
