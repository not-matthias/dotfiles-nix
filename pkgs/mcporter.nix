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
  version = "0.12.4";
  pnpm = pnpm_10;
  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "mcporter";
    tag = "v${version}";
    hash = "sha256-joLAU2hFpN2x8UFKFa/O/EJ7uoIa4ir0bwEWx9O/TYY=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit pname version src pnpm;
      fetcherVersion = 3;
      hash = "sha256-SLs44+VykZxVgn784fWrptG112tpSVIQT9zEAZKoMhc=";
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
